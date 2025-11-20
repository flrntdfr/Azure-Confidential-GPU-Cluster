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
class PrivacyArguments:
    enable_dp: bool = field(
        default=False,
        metadata={"help": "Whether to enable Differential Privacy using fastDP."}
    )
    target_epsilon: float = field(
        default=2.0,
        metadata={"help": "Target privacy budget ε."}
    )
    target_delta: Optional[float] = field(
        default=1e-5,
        metadata={"help": "Target privacy budget δ, should be smaller than 1/sample_size."}
    )
    per_sample_max_grad_norm: float = field(
        default=1.0,
        metadata={"help": "Per-sample gradient clipping threshold, default to 1. No need to tune if clipping_fn='automatic'."}
    )
    noise_multiplier: Optional[float] = field(
        default=None,
        metadata={"help": "Level of independent Gaussian noise into the gradient. This can be automatically computed by different accounting_mode if target_epsilon, batch_size, sample_size, epochs are provided."}
    )
    accounting_mode: str = field(
        default="rdp",
        metadata={"help": "Privacy accounting theory to use, one of 'rdp' (default), 'glw', 'all'."}
    )
    named_params: Optional[List[str]] = field(
        default=None,
        metadata={"help": "Specifies which parameters to optimize with differential privacy."}
    )
    clipping_mode: str = field(
        default="MixOpt",
        metadata={"help": "Per-sample gradient clipping mode, one of 'ghost', 'MixGhostClip', 'MixOpt' (default) from [4]. Note different clipping modes, including Opacus [5], GhostClip [2] and Mixed GhostClip [3], give the same convergence and accuracy though at significantly different time/space complexity."}
    )
    clipping_fn: str = field(
        default="automatic",
        metadata={"help": "Per-sample gradient clipping function to use; one of 'automatic' (default, Bu et al., 2022), 'Abadi' (Abadi et al., 2016) , 'global' (Bu et al., 2021)."}
    )
    clipping_style: str = field(
        default="all-layer",
        metadata={"help": "Per-sample gradient clipping style to use; one of all-layer (flat clipping), layer-wise (each layer is a block, including both weight and bias parameters), param-wise (each parameter is a block), or a list of layer names (general block-wise clipping)."}
    )
    origin_params: Optional[List[str]] = field(
        default=None,
        metadata={"help": "Origin parameters for the ghost differentiation trick from Bu et al. Appendix D.3. Default is None (not using the trick). To enjoy the acceleration from the trick, set to each model's first trainable layer's parameters. For example, in text classification with RoBERTa, set origin_params=['_embeddings']; in text generation with GPT2, set origin_params=['wte','wpe']; in image classification with BEiT, set origin_params=['patch_embed.proj.bias']. This trick gives about 8/6=1.666 speedup at no memory overhead."}
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
    save_strategy: str = field(
        default="no",
        metadata={"help": "The checkpoint save strategy to use."}
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
