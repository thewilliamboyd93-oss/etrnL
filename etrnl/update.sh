#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════
# EtrnL — Unified Update Script
# Handles: git push, dependency updates, formatting, tests, commit
# Usage: bash update.sh "your commit message"
# ═══════════════════════════════════════════════════════════════

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

MESSAGE="${1:-update}"

echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}${BOLD}  EtrnL — Unified Update${NC}"
echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# ── 1. Activate environment ───────────────────────────────────
echo -e "${YELLOW}[1/6]${NC} Activating environment..."
source .venv/Scripts/activate 2>/dev/null || source .venv/bin/activate 2>/dev/null
echo -e "${GREEN}OK${NC}"

# ── 2. Format code ────────────────────────────────────────────
echo -e "${YELLOW}[2/6]${NC} Formatting code..."
python.exe -m black etrnl/ tests/ --quiet 2>/dev/null || python -m black etrnl/ tests/ --quiet 2>/dev/null || true
echo -e "${GREEN}OK${NC}"

# ── 3. Lint check ─────────────────────────────────────────────
echo -e "${YELLOW}[3/6]${NC} Linting..."
python.exe -m ruff check etrnl/ tests/ --fix --quiet 2>/dev/null || python -m ruff check etrnl/ tests/ --fix --quiet 2>/dev/null || true
echo -e "${GREEN}OK${NC}"

# ── 4. Run tests ──────────────────────────────────────────────
echo -e "${YELLOW}[4/6]${NC} Running tests..."
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

# ── 5. Git add, commit ────────────────────────────────────────
echo -e "${YELLOW}[5/6]${NC} Committing: ${MESSAGE}"
git add -A
git commit -m "$MESSAGE" --quiet 2>/dev/null || echo "Nothing to commit"
echo -e "${GREEN}OK${NC}"

# ── 6. Git push ───────────────────────────────────────────────
echo -e "${YELLOW}[6/6]${NC} Pushing to GitHub..."
if git push --quiet 2>/dev/null; then
    echo -e "${GREEN}OK${NC} Pushed to GitHub"
else
    echo -e "${YELLOW}SKIP${NC} No remote configured or push failed"
    echo "  Set remote: git remote add origin https://github.com/YOUR_USERNAME/etrnL.git"
fi

# ── Done ──────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}UPDATE COMPLETE${NC}"
echo ""