# Introduction

This repository provides Infrastructure as Code (IaC) resources for the deployment and management of a confidential computing GPU cluster on Microsoft Azure, specifically tailored for research in confidential artificial intelligence. LLM finetuning and inference benchmarks are provided too.

# Features

## Cluster

- Slurm 23.11 with 2 partitions:
  - Nvidia H100 in confidential mode (flexible node count)
  - Nvidia H100 in non-confidential mode (flexible node count)
- GPU attestation on cluster creation
- PyTorch multi-node support
- Persistent shared storage
- End-to-end data encryption

# How-to

The main commands include:

```sh
~$ make login       # Login to Azure
~$ make bootstrap   # First time setup
~$ make cluster     # Create the cluster
~$ make ssh         # SSH into the login node
# ... work in the cluster: sinfo, srun, sbatch, etc. ...
~$ make destroy     # Destroy the cluster
~$ make unbootstrap # Destroy the cluster (and shared storage) TODO
```

All commands are documented with:

```sh
~$ make help
```

**Note**: a [Dev Container](.devcontainer) is provided for convenience.

## Benchmarks

Finetuning benchmarks and inference benchmarks are located in the [benchmarks](benchmarks) directory.

- Finetuning medAlpaca, single node and multi-node, with and without differential privacy.
- Inference with Gemma3 1B, Llama3.1 8B, Mistral Small 24B, Qwen3 32B, single node and multi-node.

# Requirements

- Azure subscription and a contributor or administrator role to the subscription.
- Quota for the NCC H100 v5 and NC H100 v5 SKUs.