import logging
import os
import sys
import torch
import transformers
import wandb

from arguments import (
    AdapterArguments,
    DataArguments,
    ModelArguments,
    TrainingArguments,
    WandbArguments
)
from datasets import (
    load_dataset
)
from peft import (
    LoraConfig,
    get_peft_model,
    prepare_model_for_kbit_training
)
from transformers import (
    AutoModelForCausalLM,
    AutoTokenizer,
    BitsAndBytesConfig,
    HfArgumentParser,
)
from trl import (
    SFTTrainer
)

logger = logging.getLogger(__name__)

def setup_logging(training_args, adapter_args, wandb_args):
    logging.basicConfig(
        format="%(asctime)s %(levelname)s - %(name)s: %(message)s",
        datefmt="%Z-%m-%d %H:%M:%S",
        handlers=[logging.StreamHandler(sys.stdout)]
    )
    
    log_level = training_args.get_process_log_level()
    logger.setLevel(log_level)
    
    if training_args.should_log:
        transformers.utils.logging.set_verbosity_info()
    transformers.utils.logging.set_verbosity(log_level)
    transformers.utils.logging.enable_default_handler()
    transformers.utils.logging.enable_explicit_format()
    logger.info(f"Logging {__name__}")

    if wandb_args.use_wandb:

        tags_list = []
        if adapter_args.use_lora:
            tags_list.append("lora")
        if adapter_args.load_in_4bit:
            tags_list.append("4bit")
        if adapter_args.load_in_8bit:
            tags_list.append("8bit")
        if training_args.bf16:
            tags_list.append("bf16")
        if training_args.fp16:
            tags_list.append("fp16")
        tags_list.append(f"pbs-{training_args.per_device_train_batch_size}")
        if wandb_args.wandb_tags:
            tags_list.extend(wandb_args.wandb_tags.split(","))

        wandb.init(
            project=wandb_args.wandb_project,
            name=wandb_args.wandb_run_name,
            tags=tags_list,
            notes=wandb_args.wandb_notes
        )

        training_args.report_to = ["wandb"]
        training_args.run_name = wandb_args.wandb_run_name
    else:
        training_args.report_to = [] # Explicitly disable WANDB reporting
    
    logger.info(training_args)

def get_model(model_args, adapter_args, training_args):
    dtype = torch.float32
    if training_args.bf16:
        dtype = torch.bfloat16
    elif training_args.fp16:
        dtype = torch.float16

    if adapter_args.load_in_4bit and adapter_args.load_in_8bit:
        raise ValueError("Choose either 4bit _or_ 8bit")
    
    bnb_config = None
    if adapter_args.load_in_4bit:
        bnb_config = BitsAndBytesConfig(
            load_in_4bit=True,
            bnb_4bit_quant_type="nf4",
            bnb_4bit_compute_dtype=dtype,
            bnb_4bit_use_double_quant=True,
        )
        logger.info("Will load model in 4bit")
    elif adapter_args.load_in_8bit:
        bnb_config = BitsAndBytesConfig(
            load_in_8bit=True
        )
        logger.info("Will load model in 8bit")
    
    # Model
    logger.info(f"Loading {model_args.model}")
    model = AutoModelForCausalLM.from_pretrained(
        model_args.model,
        quantization_config=bnb_config,
        device_map="auto" if not os.environ.get("LOCAL_RANK") else None,
        attn_implementation="flash_attention_2" if model_args.use_flash_attn else None,
        dtype=dtype
    )

    # Quantization
    if adapter_args.load_in_4bit or adapter_args.load_in_8bit:
        model = prepare_model_for_kbit_training(model)

    # LoRA
    if adapter_args.use_lora:
        logger.info("Applying LoRA adapters…")
        peft_config = LoraConfig(
            r=adapter_args.lora_r,
            lora_alpha=adapter_args.lora_alpha,
            lora_dropout=adapter_args.lora_dropout,
            bias="none",
            task_type="CAUSAL_LM",
            target_modules=adapter_args.lora_target_modules
        )
        model = get_peft_model(model, peft_config)
        model.print_trainable_parameters()

    return model, peft_config if adapter_args.use_lora else None

# TODO add DPTrainer

def formatting_prompts_func(example):
    instruction = example.get("instruction", "")
    input = example.get("input", "")
    output = example.get("output", "")
    prompt = f"{instruction}\n: {input}"
    text = f"{prompt} {output}"
    return text
        
def main():
    parser = HfArgumentParser((ModelArguments, DataArguments, AdapterArguments, WandbArguments, TrainingArguments))
    model_args, data_args, adapter_args, wandb_args, training_args = parser.parse_args_into_dataclasses()

    setup_logging(training_args, adapter_args, wandb_args)

    # Load model
    model, peft_config = get_model(model_args, adapter_args, training_args)

    # Load tokenizer
    tokenizer = AutoTokenizer.from_pretrained(
        model_args.model,
        padding_side="right",
        use_fast=True
    )
    tokenizer.pad_token = tokenizer.eos_token

    # Load data
    logger.info(f"Loading dataset: {data_args.dataset_path}")
    dataset = load_dataset("json", data_files=data_args.dataset_path)

    # Init the trainer
    trainer = SFTTrainer(
        model=model,
        train_dataset=dataset["train"],
        eval_dataset=dataset["test"] if "test" in dataset else None,
        peft_config=peft_config,
        processing_class=tokenizer,
        args=training_args,
        formatting_func=formatting_prompts_func,
    )

    # Train
    logger.info("Starting training")
    train_result = trainer.train()

    # Save model or not
    if training_args.should_save: # TODO check if all checkpoints are disbaled
        trainer.save_model()
    
    # Metrics
    metrics = train_result.metrics
    trainer.log_metrics("train", metrics)
    trainer.save_metrics("train", metrics)

if __name__ == "__main__":
    main()
