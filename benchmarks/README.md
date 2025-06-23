# Slurm scripts

This folder contains the slurm scripts used for benchmarking. They are provisioned on the login node during cluster creation.

## Use cases

- Finetuning medAlpaca based on [Reproducible medAlpaca](https://github.com/flrntdfr/medAlpaca)[^1].
- Inference with vLLM based on [vLLM-0.9.1 benchmarks](https://github.com/vllm-project/vllm/tree/v0.9.1/benchmarks).

## Usage

```bash
~$ cd /shared/slurm/
~$ make finetuning
~$ make inference
~$ make help
```

## Notes

- Running all the benchmarks can take ... minutes.

[^1]: Fork of [medAlpaca](https://github.com/kbressem/medAlpaca).