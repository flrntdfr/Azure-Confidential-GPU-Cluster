git clone --depth=1 --branch reproducible https://github.com/flrntdfr/medAlpaca.git
cd medAlpaca
uv venv --prompt medAlapaca --python 3.10.8
source .venv/bin/activate
uv pip install -r requirements.txt