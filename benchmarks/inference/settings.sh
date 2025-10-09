#!/bin/bash
# vLLM Configuration Settings
# This file contains all configurable variables for vLLM inference scripts

# Environment variables
export OMP_NUM_THREADS=32
export TOKENIZERS_PARALLELISM=false

# ----- #
# MODEL #
# ----- #

MODEL=meta-llama/Llama-3.1-8B-Instruct
TOKENIZER=meta-llama/Llama-3.1-8B-Instruct

# ------ #
# SERVER #
# ------ #

MAX_MODEL_LEN=8192
MAX_NUM_SEQS=256

# --------- #
# BENCHMARK #
# --------- #

DATASET_NAME="random"
RANDOM_INPUT_LEN=128
RANDOM_OUTPUT_LEN=128
NUM_PROMPTS=200
MAX_CONCURRENCY=8
TEMPERATURE=0
TIMEOUT=600
