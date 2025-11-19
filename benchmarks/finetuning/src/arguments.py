from dataclasses import dataclass, field
from typing import Optional, Tuple, List
from trl import SFTConfig

@dataclass
class AdapterArguments:
    use_lora: bool = field(
        default=False,
        metadata={"help": "Whether to use LoRA for parameter-efficient fine-tuning."}
    )
    lora_r: int = field(
        default=8,
        metadata={"help": "LoRA rank."}
    )
    lora_alpha: int = field(
        default=16,
        metadata={"help": "LoRA alpha."}
    )
    lora_dropout: float = field(
        default=0.1,
        metadata={"help": "LoRA dropout."}
    )
    lora_target_modules: Tuple[str] = field(
        default= ("q_proj", "v_proj"),
        metadata={"help": "List of module names to target with LoRA."}
    )
    load_in_4bit: bool = field(
        default=False,
        metadata={"help": "Whether to use 4-bit quantization."}
    )
    load_in_8bit: bool = field(
        default=False,
        metadata={"help": "Whether to use 8-bit quantization."}
    )

@dataclass
class DataArguments:
    dataset_path: str = field(
        default="data/medical_meadow_small.json",
        metadata={"help": "Path to the training dataset (JSON file)."}
    )

@dataclass
class ModelArguments:
    model: str = field(
        default="meta-llama/Llama-2-7b-hf",
        metadata={"help": "Path to pretrained model or model identifier from huggingface.co/models"}
    )
    use_flash_attn: bool = field(
        default=False,
        metadata={"help": "Whether to use Flash Attention 2.0"}
    )

@dataclass
class TrainingArguments(SFTConfig):
    seed: int = field(
        default=54940,
        metadata={"help": "The seed"}
    )
    max_seq_length: int = field(
        default=512,
        metadata={"help": "The maximum total input sequence length after tokenization."}
    )
    per_device_train_batch_size: int = field(
        default=8,
        metadata={"help": "Batch size per GPU for training."}
    )
    per_device_eval_batch_size: int = field(
        default=8,
        metadata={"help": "Batch size per GPU for evaluation."}
    )
    learning_rate: float = field(
        default=2e-5, 
        metadata={"help": "The initial learning rate for AdamW."}
    )
    num_train_epochs: float = field(
        default=3.0, 
        metadata={"help": "Total number of training epochs to perform."}
    )
    warmup_steps: int = field(
        default=100, 
        metadata={"help": "Linear warmup over warmup_steps."}
    )
    logging_steps: int = field(
        default=100, 
        metadata={"help": "Log every X updates steps."}
    )
    optim: str = field(
        default="adamw_torch", 
        metadata={"help": "The optimizer to use."}
    )
    lr_scheduler_type: str = field(
        default="cosine", 
        metadata={"help": "The scheduler type to use."}
    )
    gradient_checkpointing: bool = field(
        default=False, 
        metadata={"help": "If True, use gradient checkpointing to save memory at the expense of slower backward pass."}
    )
    bf16: bool = field(
        default=True, 
        metadata={"help": "Whether to use bf16 (mixed) precision instead of 32-bit."}
    )
    fp16: bool = field(
        default=False, 
        metadata={"help": "Whether to use fp16 (mixed) precision instead of 32-bit."}
    )
    group_by_length: bool = field(
        default=True, 
        metadata={"help": "Whether or not to group together samples of roughly the same length in the training dataset."}
    )

# privacy_engine = PrivacyEngine(
#     model,
#     batch_size=256,
#     sample_size=50000,
#     epochs=3,
#     target_epsilon=2,
#     clipping_fn='automatic',
#     clipping_mode='MixOpt',
#     origin_params=None,
#     clipping_style='all-layer',
# )

@dataclass # FIXME
class PrivacyArguments:
    enable_dp: bool = field(
        default=False,
        metadata={"help": "Whether to enable Differential Privacy using fastDP."}
    )
    target_epsilon: float = field(
        default=8.0,
        metadata={"help": "The target epsilon for differential privacy."}
    )
    target_delta: float = field(
        default=1e-5,
        metadata={"help": "The target delta for differential privacy."}
    )
    max_grad_norm: float = field(
        default=1.0,
        metadata={"help": "Maximum gradient norm for clipping in DP."}
    )

@dataclass
class WandbArguments:
    use_wandb: bool = field(
        default=False,
        metadata={"help": "Whether to use Weights & Biases for logging."}
    )
    wandb_project: str = field(
        default="medalpaca",
        metadata={"help": "The Weights & Biases project name."}
    )
    wandb_run_name: str = field(
        default="test",
        metadata={"help": "The run name for Weights & Biases logging."}
    )
    wandb_tags: Optional[str] = field(
        default=None,
        metadata={"help": "Tags to be added to the Weights & Biases run. Can be a comma-separated string."}
    )
    wandb_notes: Optional[str] = field(
        default=None,
        metadata={"help": "Notes to be added to the Weights & Biases run."}
    )
