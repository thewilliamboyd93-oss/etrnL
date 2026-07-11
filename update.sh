#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════
# EtrnL — Unified Update Script
# Formats, lints, tests, installs, commits, and pushes
# Usage: bash update.sh "your commit message"
# ═══════════════════════════════════════════════════════════════

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

MESSAGE="${1:-update}"
PROJECT_DIR="$HOME/Desktop/etrnL"

echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}${BOLD}  EtrnL — Unified Update${NC}"
echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# ── Ensure we're in the right directory ──────────────────────
cd "$PROJECT_DIR"

# ── 1. Activate environment ───────────────────────────────────
echo -e "${YELLOW}[1/7]${NC} Activating environment..."
source .venv/Scripts/activate 2>/dev/null || source .venv/bin/activate 2>/dev/null
echo -e "${GREEN}OK${NC}"

# ── 2. Install package in development mode ────────────────────
echo -e "${YELLOW}[2/7]${NC} Installing package..."
pip install -e . --quiet 2>/dev/null || true
echo -e "${GREEN}OK${NC}"

# ── 3. Format code ────────────────────────────────────────────
echo -e "${YELLOW}[3/7]${NC} Formatting with Black..."
python.exe -m black etrnl/ tests/ --quiet 2>/dev/null || python -m black etrnl/ tests/ --quiet 2>/dev/null || true
echo -e "${GREEN}OK${NC}"

# ── 4. Lint with Ruff ─────────────────────────────────────────
echo -e "${YELLOW}[4/7]${NC} Linting with Ruff..."
python.exe -m ruff check etrnl/ tests/ --fix --quiet 2>/dev/null || python -m ruff check etrnl/ tests/ --fix --quiet 2>/dev/null || true
echo -e "${GREEN}OK${NC}"

# ── 5. Run tests ──────────────────────────────────────────────
echo -e "${YELLOW}[5/7]${NC} Running tests..."
if python.exe -m pytest tests/ -q --tb=short 2>/dev/null || python -m pytest tests/ -q --tb=short 2>/dev/null; then
    echo -e "${GREEN}OK${NC} All tests passed"
else
    echo -e "${RED}FAIL${NC} Tests failed — commit anyway? [y/N]: "
    read -r RESPONSE
    if [[ ! "$RESPONSE" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# ── 6. Git add and commit ─────────────────────────────────────
echo -e "${YELLOW}[6/7]${NC} Committing: ${MESSAGE}"
git add -A
git commit -m "$MESSAGE" --quiet 2>/dev/null || echo "Nothing to commit"
echo -e "${GREEN}OK${NC}"

# ── 7. Git push ───────────────────────────────────────────────
echo -e "${YELLOW}[7/7]${NC} Pushing to GitHub..."
if git push --quiet 2>/dev/null; then
    echo -e "${GREEN}OK${NC} Pushed to GitHub"
else
    echo -e "${YELLOW}SKIP${NC} Push failed — check your connection"
fi

# ── Done ──────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}UPDATE COMPLETE${NC}"
echo ""
