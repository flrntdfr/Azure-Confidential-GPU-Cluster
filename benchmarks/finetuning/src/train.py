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
    PrivacyArguments,
    TrainingArguments,
    WandbArguments,
)
from datasets import load_dataset
from peft import LoraConfig, get_peft_model, prepare_model_for_kbit_training
from transformers import (
    AutoModelForCausalLM,
    AutoTokenizer,
    BitsAndBytesConfig,
    HfArgumentParser,
    set_seed,
)
from trl import SFTTrainer

logger = logging.getLogger(__name__)

def setup_logging(adapter_args, privacy_args, training_args, wandb_args):
    logging.basicConfig(
        format="%(asctime)s %(levelname)s - %(name)s: %(message)s",
        datefmt="%Z-%m-%d %H:%M:%S",
        handlers=[logging.StreamHandler(sys.stdout)],
        force=True,
    )

    log_level = logging.DEBUG
    logger.setLevel(log_level)

    if training_args.should_log:
        transformers.utils.logging.set_verbosity_info()
    transformers.utils.logging.set_verbosity(log_level)
    transformers.utils.logging.enable_default_handler()
    transformers.utils.logging.enable_explicit_format()
    logger.info(f"Logging {__name__}")

    if wandb_args.use_wandb:
        tags_list = []
        notes = ""
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
        if privacy_args.enable_dp:
            tags_list.append("BitFit")
            tags_list.append("ε-" + str(privacy_args.target_epsilon))
            notes += "DP settings:"
            notes += f"epsilon: {privacy_args.target_epsilon}"
            notes += f"delta: {privacy_args.target_delta}"
            notes += f"max_grad_norm: {privacy_args.per_sample_max_grad_norm}"
            notes += f"noise_multiplier: {privacy_args.noise_multiplier}"
            notes += f"accounting_mode: {privacy_args.accounting_mode}"
            notes += f"clipping_mode: {privacy_args.clipping_mode}"
            notes += f"clipping_fn: {privacy_args.clipping_fn}"
            notes += f"clipping_style: {privacy_args.clipping_style}"
            notes += f"origin_params: {privacy_args.origin_params}"
            notes += f"named_params: {privacy_args.named_params}"
        if wandb_args.wandb_tags:
            tags_list.extend([str(tag) for tag in wandb_args.wandb_tags.split(",")])
        if wandb_args.wandb_notes:
            notes += wandb_args.wandb_notes
        
        wandb.init(
            project=wandb_args.wandb_project,
            name=wandb_args.wandb_run_name,
            tags=tags_list,
            notes=notes,
        )

        training_args.report_to = ["wandb"]
        training_args.run_name = wandb_args.wandb_run_name
    else:
        training_args.report_to = []  # Explicitly disable WANDB reporting

    logger.debug(adapter_args)
    logger.debug(privacy_args)
    logger.debug(training_args)


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
        bnb_config = BitsAndBytesConfig(load_in_8bit=True)
        logger.info("Will load model in 8bit")

    # Model
    logger.info(f"Loading {model_args.model}")
    model = AutoModelForCausalLM.from_pretrained(
        model_args.model,
        quantization_config=bnb_config,
        device_map="auto" if not os.environ.get("LOCAL_RANK") else None,
        attn_implementation="flash_attention_2" if model_args.use_flash_attn else None,
        dtype=dtype,
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
            target_modules=adapter_args.lora_target_modules,
        )
        model = get_peft_model(model, peft_config)
        model.print_trainable_parameters()

    return model, peft_config if adapter_args.use_lora else None


class DPTrainer(SFTTrainer):
    def __init__(self, privacy_args, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.privacy_args = privacy_args
        assert self.privacy_args.target_delta < 1 / len(self.train_dataset), "Target privacy budget δ, should be smaller than 1/sample_size."

    def create_optimizer(self):
        """Wrap the optimizer with the PrivacyEngine"""
        from fastDP import PrivacyEngine

        optimizer = super().create_optimizer()
        logger.info("Wrapping optimizer with fastDP PrivacyEngine")
        self.privacy_engine = PrivacyEngine(
            self.model,
            batch_size=self.args.per_device_train_batch_size * self.args.gradient_accumulation_steps,
            sample_size=len(self.train_dataset),
            epochs=self.args.num_train_epochs,
            target_epsilon=self.privacy_args.target_epsilon,
            target_delta=self.privacy_args.target_delta,
            max_grad_norm=self.privacy_args.per_sample_max_grad_norm,
            noise_multiplier=self.privacy_args.noise_multiplier,
            accounting_mode=self.privacy_args.accounting_mode,
            clipping_mode=self.privacy_args.clipping_mode,
            clipping_fn=self.privacy_args.clipping_fn,
            clipping_style=self.privacy_args.clipping_style,
            origin_params=self.privacy_args.origin_params,
            named_params=self.privacy_args.named_params,
        )
        self.privacy_engine.attach(optimizer)

        # ----- BEGIN HACK ---- #
        import types
        original_step = optimizer.step

        def step_with_positional_closure(_self, closure=None, **kwargs):
            return original_step(closure=closure, **kwargs)
        
        optimizer.step = types.MethodType(step_with_positional_closure, optimizer)
        # ----- END HACK -----#

        logger.info("Privacy engine attached!")
        return optimizer


def formatting_prompts_func(example):
    instruction = example.get("instruction", "")
    input = example.get("input", "")
    output = example.get("output", "")
    prompt = f"{instruction}\n: {input}"
    text = f"{prompt} {output}"
    return text


def main():
    parser = HfArgumentParser(
        (
            AdapterArguments,
            DataArguments,
            ModelArguments,
            PrivacyArguments,
            TrainingArguments,
            WandbArguments,
        )
    )
    adapter_args, data_args, model_args, privacy_args, training_args, wandb_args = (
        parser.parse_args_into_dataclasses()
    )

    set_seed(training_args.seed)

    setup_logging(adapter_args, privacy_args, training_args, wandb_args)

    # Load model
    model, peft_config = get_model(model_args, adapter_args, training_args)

    # Load tokenizer
    tokenizer = AutoTokenizer.from_pretrained(
        model_args.model, padding_side="right", use_fast=True
    )
    tokenizer.pad_token = tokenizer.eos_token

    # Load data
    logger.info(f"Loading dataset: {data_args.dataset_path}")
    dataset = load_dataset("json", data_files=data_args.dataset_path)

    TrainerClass = DPTrainer if privacy_args.enable_dp else SFTTrainer

    # Init the trainer
    trainer_kwargs = {
        "model": model,
        "train_dataset": dataset["train"],
        "eval_dataset": dataset["test"] if "test" in dataset else None,
        "peft_config": peft_config,
        "processing_class": tokenizer,
        "args": training_args,
        "formatting_func": formatting_prompts_func,
    }

    if privacy_args.enable_dp:
        trainer_kwargs["privacy_args"] = privacy_args

    trainer = TrainerClass(**trainer_kwargs)

    # Train
    logger.info("Starting training")
    train_result = trainer.train()

    # Save model or not
    if training_args.save_strategy != "no":
        trainer.save_model()

    # Metrics
    metrics = train_result.metrics
    trainer.log_metrics("train", metrics)
    trainer.save_metrics("train", metrics)


if __name__ == "__main__":
    main()
