# Introduction

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin vel leo hendrerit, lobortis lacus vel, faucibus magna. Vivamus vel neque quis ante condimentum molestie ac a augue. In bibendum diam et diam lacinia, quis finibus nibh dictum. Etiam est ipsum, vulputate non placerat id, porttitor at nisi. Nunc pellentesque sem sed massa lobortis lacinia. Donec non urna sed mi semper pulvinar eu et metus. Maecenas sit amet nibh turpis. Aliquam commodo massa sed libero aliquet eleifend. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin in placerat nunc. Sed gravida posuere pretium. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae;

# How-to

The main commands include:

```sh
~$ make login     # Login to Azure
~$ make bootstrap # First time setup
~$ make cluster   # Create the cluster
# ... work in the cluster: sinfo, srun, sbatch, etc. ...
~$ make destroy   # Destroy the cluster
```

All commands are documented with:

```sh
~$ make help
```

Note: a [Dev Container](.devcontainer) is provided for convenience.

# Requirements

- Azure subscription and a contributor or administrator role to the subscription
- Quota for the NCC H100 v5 VM SKU
- Install Azure CLI

# Configuration

## Cloud configuration

- Put your credentials in .env

## Cluster configuration

- Adapt vars.tf

# Citation

```bibtex
@article{dufour2025confidential,
  title={Confidential Computing with SLURM},
  author={Dufour, Florent},
  journal={arXiv preprint arXiv:2503.07449},
  year={2025}
}