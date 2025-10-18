# Test with varying prefill/decode ratios
# Short prompt, long generation (decode-heavy)
RANDOM_INPUT_LEN=32
RANDOM_OUTPUT_LEN=512

# Long prompt, short generation (prefill-heavy)
RANDOM_INPUT_LEN=512
RANDOM_OUTPUT_LEN=32

# Collect detailed timing breakdown if available

TEMPERATURE=0.7