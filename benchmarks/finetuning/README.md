# Finetuning Benchmark

## Overview

This benchmark is used to finetune medAlpaca on the medical_meadow dataset in single node, multi-node, and with differential privacy.

## Usage

```sh
~$ make bootstrap   # Bootstrap the training code and dataset
~$ make benchmark   # Submit the experiments
~$ make zip         # Collect the results
```