#!/usr/bin/env bash
set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# EtrnL — Complete Environment Prerequisites
# Usage: bash setup_environment.sh
# ══════════════════════════════════════════════════════════════════════════════

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

check_ok() { echo -e "${GREEN}✓${NC} $1"; }
check_info() { echo -e "${BLUE}→${NC} $1"; }
check_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
check_fail() { echo -e "${RED}✗${NC} $1"; }

echo ""
echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}${BOLD}  EtrnL — Environment Prerequisites${NC}"
echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# ── Detect OS ─────────────────────────────────────────────────────────────────
OS="$(uname -s)"
if [[ "$OS" == "Darwin" ]]; then
    PLATFORM="macos"
elif [[ "$OS" == "Linux" ]]; then
    PLATFORM="linux"
else
    check_fail "Unsupported OS: $OS"
    exit 1
fi
check_info "Platform: $PLATFORM"

# ── Find Python ───────────────────────────────────────────────────────────────
PYTHON_CMD=""
for cmd in python3.12 python3.11 python3; do
    if command -v "$cmd" &> /dev/null; then
        VERSION=$("$cmd" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
        if [[ "${VERSION%.*}" -ge 3 ]] && [[ "${VERSION#*.}" -ge 11 ]]; then
            PYTHON_CMD="$cmd"
            check_ok "Python $VERSION found: $PYTHON_CMD"
            break
        fi
    fi
done

if [[ -z "$PYTHON_CMD" ]]; then
    check_fail "Python 3.11+ required. Install from https://www.python.org/downloads/"
    exit 1
fi

# ── Check Git ─────────────────────────────────────────────────────────────────
if command -v git &> /dev/null; then
    check_ok "Git: $(git --version 2>&1)"
else
    check_fail "Git not found. Install from https://git-scm.com/download/win"
    exit 1
fi

# ── Configure Git ─────────────────────────────────────────────────────────────
if [[ -z "$(git config --global user.name 2>/dev/null || true)" ]]; then
    echo ""
    check_warn "Git user.name not configured."
    echo "  Enter your name for git commits:"
    read -r GIT_NAME
    git config --global user.name "$GIT_NAME"
    check_ok "Git user.name set to: $GIT_NAME"
fi

if [[ -z "$(git config --global user.email 2>/dev/null || true)" ]]; then
    echo ""
    check_warn "Git user.email not configured."
    echo "  Enter your email for git commits:"
    read -r GIT_EMAIL
    git config --global user.email "$GIT_EMAIL"
    check_ok "Git user.email set to: $GIT_EMAIL"
fi

# ── Check VS Codium ──────────────────────────────────────────────────────────
if command -v codium &> /dev/null; then
    check_ok "VS Codium found"
elif [[ -f "/Applications/VSCodium.app/Contents/Resources/app/bin/codium" ]]; then
    check_ok "VS Codium found (Applications)"
elif [[ -f "$HOME/AppData/Local/Programs/VSCodium/bin/codium.cmd" ]]; then
    check_ok "VS Codium found (Windows)"
elif [[ -f "/usr/bin/codium" ]]; then
    check_ok "VS Codium found (Linux)"
else
    check_warn "VS Codium not found in PATH."
    echo "  Install from: https://vscodium.com"
    echo "  Or use VS Code if already installed."
fi

# ── Create Project ────────────────────────────────────────────────────────────
PROJECT_DIR="$HOME/Desktop/etrnL"
VENV_DIR="$PROJECT_DIR/.venv"

mkdir -p "$PROJECT_DIR"
check_ok "Project directory: $PROJECT_DIR"

# ── Virtual Environment ──────────────────────────────────────────────────────
if [[ -d "$VENV_DIR" ]]; then
    check_warn "Virtual environment already exists."
    echo "  Recreate? [y/N]: "
    read -r RECREATE
    if [[ "$RECREATE" =~ ^[Yy]$ ]]; then
        rm -rf "$VENV_DIR"
        check_info "Creating fresh virtual environment..."
        "$PYTHON_CMD" -m venv "$VENV_DIR"
        check_ok "Virtual environment recreated"
    else
        check_ok "Using existing virtual environment"
    fi
else
    check_info "Creating virtual environment..."
    "$PYTHON_CMD" -m venv "$VENV_DIR"
    check_ok "Virtual environment created"
fi

# ── Activate and Install Dependencies ─────────────────────────────────────────
# shellcheck disable=SC1090
source "$VENV_DIR/bin/activate" 2>/dev/null || source bash  2>/dev/null || {
    check_fail "Could not activate virtual environment"
    exit 1
}

pip install --upgrade pip setuptools wheel --quiet
check_ok "pip upgraded"

check_info "Installing scientific packages..."
pip install numpy scipy scikit-learn matplotlib --quiet
check_ok "numpy, scipy, scikit-learn, matplotlib"

check_info "Installing PyTorch (CPU)..."
pip install torch --index-url https://download.pytorch.org/whl/cpu --quiet
check_ok "PyTorch $(python -c 'import torch; print(torch.__version__)')"

check_info "Installing ML/AI packages..."
pip install qdrant-client transformers diffusers --quiet
check_ok "qdrant-client, transformers, diffusers"

check_info "Installing security packages..."
pip install cryptography blake3 --quiet
check_ok "cryptography, blake3"

check_info "Installing config packages..."
pip install pydantic pyyaml jsonschema --quiet
check_ok "pydantic, pyyaml, jsonschema"

check_info "Installing dev tools..."
pip install pytest pytest-cov black ruff --quiet
check_ok "pytest, black, ruff"

# ── Verify ────────────────────────────────────────────────────────────────────
echo ""
check_info "Verifying installation..."

VERIFY_OK=true
verify_module() {
    if python -c "$2" 2>/dev/null; then
        check_ok "$1"
    else
        check_fail "$1"
        VERIFY_OK=false
    fi
}

verify_module "Python 3.11+" "import sys; assert sys.version_info >= (3, 11)"
verify_module "PyTorch" "import torch; print(f'  {torch.__version__}')"
verify_module "NumPy" "import numpy"
verify_module "pytest" "import pytest"
verify_module "Black" "import black"
verify_module "Ruff" "import ruff"

# ── Create Activate Script ────────────────────────────────────────────────────
cat > "$PROJECT_DIR/activate.sh" << 'ACTIVATE'
#!/usr/bin/env bash
# Activate EtrnL development environment
PROJECT_DIR="$HOME/Desktop/etrnL"
source "$PROJECT_DIR/.venv/bin/activate" 2>/dev/null || source "$PROJECT_DIR/.venv/Scripts/activate"
cd "$PROJECT_DIR" || exit
echo "EtrnL environment activated."
echo "Python: $(python --version)"
echo "Project: $(pwd)"
ACTIVATE
chmod +x "$PROJECT_DIR/activate.sh"
check_ok "Activate script created: activate.sh"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
if [[ "$VERIFY_OK" == "true" ]]; then
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║  ALL PREREQUISITES INSTALLED SUCCESSFULLY                     ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
else
    echo -e "${RED}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}${BOLD}║  SOME CHECKS FAILED — Review errors above                    ║${NC}"
    echo -e "${RED}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
fi

echo ""
echo -e "${BOLD}To start working:${NC}"
echo -e "  cd $PROJECT_DIR"
echo -e "  source .venv/bin/activate    ${GREEN}# (or: source activate.sh)${NC}"
echo -e "  codium .                     ${GREEN}# Open VS Codium${NC}"
echo ""
echo -e "${BOLD}Next: Run the build script${NC}"
echo -e "  bash build.sh"