cd ~/Desktop/etrnL
rm -rf .venv
python -m venv .venv
source .venv/Scripts/activate
pip install --upgrade pip
pip install torch numpy scipy scikit-learn matplotlib --index-url https://download.pytorch.org/whl/cpu
pip install qdrant-client cryptography blake3 pydantic pyyaml
pip install pytest pytest-cov black ruff