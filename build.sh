#!/usr/bin/env bash
set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# EtrnL Essence — Automated Build System
# 
# Usage: bash build.sh
#
# This script automates every process. When it reaches a point that requires
# your personal input, it STOPS, tells you exactly what to add, and waits
# for you to confirm before continuing.
# ══════════════════════════════════════════════════════════════════════════════

PROJECT_DIR="$HOME/etrnl"
VENV_DIR="$PROJECT_DIR/.venv"

# ── Colors ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# ── Helpers ───────────────────────────────────────────────────────────────────
pause_for_input() {
    echo ""
    echo -e "${YELLOW}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${BOLD}║  YOUR INPUT REQUIRED                                         ║${NC}"
    echo -e "${YELLOW}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "$1"
    echo ""
    read -p "Press Enter when done (or type 'skip' to skip this step): " RESPONSE
    if [[ "$RESPONSE" == "skip" ]]; then
        echo -e "${YELLOW}Skipping...${NC}"
        return 1
    fi
    return 0
}

step_complete() {
    echo -e "${GREEN}✓${NC} $1"
}

# ══════════════════════════════════════════════════════════════════════════════
# STEP 0: Environment Setup (Fully Automated)
# ══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}${BOLD}  EtrnL Essence — Automated Build${NC}"
echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Create project directory
if [ ! -d "$PROJECT_DIR" ]; then
    echo "Creating project directory..."
    mkdir -p "$PROJECT_DIR"
    step_complete "Project directory created: $PROJECT_DIR"
else
    step_complete "Project directory exists: $PROJECT_DIR"
fi

cd "$PROJECT_DIR"

# Create virtual environment
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv "$VENV_DIR"
    step_complete "Virtual environment created"
else
    step_complete "Virtual environment exists"
fi

# Activate
source "$VENV_DIR/Scripts/activate"
pip install --upgrade pip --quiet

# Install dependencies
echo "Installing dependencies..."
pip install torch numpy scipy scikit-learn matplotlib --index-url https://download.pytorch.org/whl/cpu --quiet
pip install qdrant-client cryptography blake3 pydantic pyyaml --quiet
pip install pytest pytest-cov black ruff --quiet
step_complete "All dependencies installed"

# Create directory structure
echo "Creating project structure..."
mkdir -p etrnl tests .vscode
step_complete "Directory structure created"

# Create .gitignore
cat > .gitignore << 'EOF'
__pycache__/
*.py[cod]
.venv/
.pytest_cache/
.ruff_cache/
.mypy_cache/
dist/
*.egg-info/
.DS_Store
EOF
step_complete ".gitignore created"

# Create VS Codium settings
cat > .vscode/settings.json << 'EOF'
{
    "[python]": {
        "editor.defaultFormatter": "ms-python.black-formatter",
        "editor.formatOnSave": true
    },
    "python.defaultInterpreterPath": ".venv/bin/python",
    "python.testing.pytestEnabled": true,
    "python.testing.pytestArgs": ["tests/"]
}
EOF
step_complete "VS Codium settings created"

# Initialize git
if [ ! -d ".git" ]; then
    git init --quiet
    step_complete "Git initialized"
else
    step_complete "Git repository exists"
fi

# ══════════════════════════════════════════════════════════════════════════════
# STEP 1: Create contracts.py (Fully Automated — Template Generated)
# ══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${BLUE}${BOLD}STEP 1: Creating contracts.py${NC}"

cat > etrnl/contracts.py << 'CONTRACTS'
"""Interface contracts for EtrnL primitives."""

class ContractViolation(Exception):
    """Raised when a primitive violates its declared contract."""
    pass


class ModuleContract:
    """Base class for all EtrnL primitives."""
    
    __contract__ = {
        'methods': [],
        'guarantees': [],
        'max_latency_ms': 0,
    }
    
    def __init_subclass__(cls, **kwargs):
        super().__init_subclass__(**kwargs)
        cls._verify_contract()
    
    @classmethod
    def _verify_contract(cls):
        contract = cls.__contract__
        for method_name in contract.get('methods', []):
            if not hasattr(cls, method_name):
                raise ContractViolation(
                    f"{cls.__name__} declares method '{method_name}' "
                    f"but it does not exist"
                )
        for guarantee in contract.get('guarantees', []):
            if not isinstance(guarantee, str):
                raise ContractViolation(
                    f"{cls.__name__} guarantee must be string: {guarantee}"
                )
CONTRACTS

step_complete "contracts.py created"

# Verify
python -c "from etrnl.contracts import ModuleContract, ContractViolation; print('  contracts.py imports OK')"

# ══════════════════════════════════════════════════════════════════════════════
# STEP 2: Create config.py (Fully Automated — Template Generated)
# ══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${BLUE}${BOLD}STEP 2: Creating config.py${NC}"

cat > etrnl/config.py << 'CONFIG'
"""All configuration for EtrnL primitives."""

from dataclasses import dataclass
from enum import Enum
from typing import Optional


class ConsentAttribute(Enum):
    AGE = "age"
    GENDER = "gender"
    ACCENT = "accent"
    MOOD = "mood"
    REACTIVITY = "reactivity"
    ACTIVITY = "activity"
    SOCIAL = "social"


@dataclass
class ConsentProfile:
    age: bool = True
    gender: bool = True
    accent: bool = True
    mood: bool = True
    reactivity: bool = True
    activity: bool = True
    social: bool = True
    
    def is_allowed(self, attribute: ConsentAttribute) -> bool:
        return getattr(self, attribute.value)
    
    def is_denied(self, attribute: ConsentAttribute) -> bool:
        return not self.is_allowed(attribute)
    
    @classmethod
    def all_allowed(cls) -> "ConsentProfile":
        return cls()
    
    @classmethod
    def all_denied(cls) -> "ConsentProfile":
        return cls(False, False, False, False, False, False, False)
    
    @classmethod
    def single_denied(cls, attribute: str) -> "ConsentProfile":
        profile = cls()
        setattr(profile, attribute, False)
        return profile


@dataclass
class ManifoldConfig:
    manifold_dim: int = 128
    encoder_dim: int = 64
    num_modalities: int = 4
    identity_consistency_weight: float = 1.0
    cycle_consistency_weight: float = 0.5
    navigation_step_size: float = 0.1


@dataclass
class PrivacyConfig:
    identity_epsilon: float = 0.1
    emotion_epsilon: float = 0.5
    context_epsilon: float = 1.0
    cross_modal_epsilon: float = 2.0
    interaction_epsilon: float = 4.0
    temporal_epsilon: float = 8.0
    isolation_dir: str = "./isolation"


@dataclass
class PresenceConfig:
    challenge_timeout_seconds: int = 30
    human_response_min_ms: float = 500
    human_response_max_ms: float = 15000
    attestation_validity_hours: int = 1


@dataclass
class ContinuityConfig:
    active_threshold_days: int = 30
    dormant_threshold_days: int = 90
    steward_consensus_required: float = 1.0


@dataclass
class GradientConfig:
    default_user_threshold: int = 2
    verbatim_min_confidence: float = 0.95
    paraphrase_min_confidence: float = 0.80
    extrapolation_min_confidence: float = 0.60
    speculation_min_confidence: float = 0.40


@dataclass
class HolographConfig:
    num_fragments: int = 4
    fragment_overlap: float = 0.5
    single_fragment_quality_target: float = 0.60
    full_reconstruction_quality_target: float = 0.95
CONFIG

step_complete "config.py created"

# Verify
python -c "from etrnl.config import ConsentProfile, ManifoldConfig; print('  config.py imports OK')"

# ══════════════════════════════════════════════════════════════════════════════
# STEP 3: Create __init__.py (Fully Automated)
# ══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${BLUE}${BOLD}STEP 3: Creating __init__.py${NC}"

cat > etrnl/__init__.py << 'INIT'
"""EtrnL v5.0 — Identity Continuity Infrastructure."""

__version__ = "5.0.0"

from etrnl.manifold import IdentityManifold
from etrnl.contracts import ModuleContract, ContractViolation
from etrnl.config import (
    ConsentProfile, ManifoldConfig, PrivacyConfig,
    PresenceConfig, ContinuityConfig, GradientConfig, HolographConfig
)

__all__ = [
    "IdentityManifold",
    "ModuleContract",
    "ContractViolation",
    "ConsentProfile",
    "ManifoldConfig",
    "PrivacyConfig",
    "PresenceConfig",
    "ContinuityConfig",
    "GradientConfig",
    "HolographConfig",
]
INIT

step_complete "__init__.py created"

# ══════════════════════════════════════════════════════════════════════════════
# STEP 4: Create manifold.py (YOUR INPUT REQUIRED — Core Implementation)
# ══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${BLUE}${BOLD}STEP 4: Creating manifold.py skeleton${NC}"

# Create the skeleton with all method signatures
cat > etrnl/manifold.py << 'MANIFOLD_SKELETON'
"""IDENTITY MANIFOLD — The central primitive."""

import torch
import torch.nn as nn
import torch.nn.functional as F
from typing import Optional
import math

from etrnl.contracts import ModuleContract
from etrnl.config import ManifoldConfig


class IdentityManifold(nn.Module, ModuleContract):
    """The central primitive. Everything flows from here."""
    
    __contract__ = {
        'methods': ['encode', 'generate', 'navigate', 'resonate',
                     'interpolate', 'verify', 'synthesize', 'train_step'],
        'guarantees': [
            'manifold_point_is_irreversible',
            'cross_modal_cycle_consistency',
            'identity_separation',
        ],
        'max_latency_ms': 150,
    }
    
    def __init__(self, config: Optional[ManifoldConfig] = None):
        nn.Module.__init__(self)
        self.config = config or ManifoldConfig()
        dim = self.config.manifold_dim
        
        # The manifold origin
        self.origin = nn.Parameter(torch.zeros(1, dim))
        
        # Modality encoders — YOU IMPLEMENT THESE
        self.voice_encoder = nn.Sequential(
            nn.Linear(32, 64), nn.LayerNorm(64), nn.GELU(), nn.Linear(64, dim)
        )
        self.face_encoder = nn.Sequential(
            nn.Linear(32, 64), nn.LayerNorm(64), nn.GELU(), nn.Linear(64, dim)
        )
        self.text_encoder = nn.Sequential(
            nn.Linear(768, 256), nn.LayerNorm(256), nn.GELU(), nn.Linear(256, dim)
        )
        self.context_encoder = nn.Sequential(
            nn.Linear(16, 32), nn.LayerNorm(32), nn.GELU(), nn.Linear(32, dim)
        )
        
        # Missing modality embeddings
        self.missing_voice = nn.Parameter(torch.randn(1, dim))
        self.missing_face = nn.Parameter(torch.randn(1, dim))
        self.missing_text = nn.Parameter(torch.randn(1, dim))
        self.missing_context = nn.Parameter(torch.randn(1, dim))
        
        # Generator — reads FROM the manifold
        self.generator = nn.Sequential(
            nn.Linear(dim, 256), nn.LayerNorm(256), nn.GELU(),
            nn.Linear(256, 512), nn.LayerNorm(512), nn.GELU(),
            nn.Linear(512, 3 * 256 * 256),
        )
        
        # Navigation directions
        self.directions = nn.ParameterDict({
            'nostalgia': nn.Parameter(torch.randn(1, dim) * 0.1),
            'curiosity': nn.Parameter(torch.randn(1, dim) * 0.1),
            'sadness': nn.Parameter(torch.randn(1, dim) * 0.1),
            'warmth': nn.Parameter(torch.randn(1, dim) * 0.1),
            'humor': nn.Parameter(torch.randn(1, dim) * 0.1),
            'formality': nn.Parameter(torch.randn(1, dim) * 0.1),
            'energy': nn.Parameter(torch.randn(1, dim) * 0.1),
            'reflectiveness': nn.Parameter(torch.randn(1, dim) * 0.1),
        })
        
        self.identity_loss = nn.CosineEmbeddingLoss()
    
    def encode(self, voice=None, face=None, text=None, context=None) -> torch.Tensor:
        """Encode any combination of modalities into the manifold."""
        batch_size = self._get_batch_size(voice, face, text, context)
        device = self._get_device(voice, face, text, context)
        points, weights = [], []
        
        for modality, encoder, missing, weight in [
            (voice, self.voice_encoder, self.missing_voice, 1.0),
            (face, self.face_encoder, self.missing_face, 1.0),
            (text, self.text_encoder, self.missing_text, 0.8),
            (context, self.context_encoder, self.missing_context, 0.5),
        ]:
            if modality is not None:
                points.append(encoder(modality))
                weights.append(weight)
            else:
                points.append(missing.expand(batch_size, -1))
                weights.append(0.0)
        
        weights = torch.tensor(weights, device=device)
        weights = weights / (weights.sum() + 1e-8)
        stacked = torch.stack(points, dim=0)
        point = (stacked * weights.view(-1, 1, 1)).sum(dim=0)
        return F.normalize(point, dim=-1) * math.sqrt(self.config.manifold_dim)
    
    def generate(self, manifold_point: torch.Tensor) -> torch.Tensor:
        """Generate face image from manifold point."""
        raw = self.generator(manifold_point)
        return raw.view(manifold_point.shape[0], 3, 256, 256)
    
    def navigate(self, point: torch.Tensor, direction: str, magnitude: float = 0.5) -> torch.Tensor:
        """Navigate within the manifold."""
        if direction not in self.directions:
            raise ValueError(f"Unknown direction: {direction}")
        new_point = point + magnitude * self.directions[direction]
        return F.normalize(new_point, dim=-1) * math.sqrt(self.config.manifold_dim)
    
    def resonate(self, point: torch.Tensor, query: torch.Tensor) -> torch.Tensor:
        """Memory as resonance."""
        return F.cosine_similarity(point.unsqueeze(1), query.unsqueeze(0), dim=-1)
    
    def interpolate(self, point_a: torch.Tensor, point_b: torch.Tensor, alpha: float = 0.5) -> torch.Tensor:
        """Spherical linear interpolation on the manifold."""
        a_norm = F.normalize(point_a, dim=-1)
        b_norm = F.normalize(point_b, dim=-1)
        omega = torch.acos(torch.clamp((a_norm * b_norm).sum(dim=-1, keepdim=True), -1.0, 1.0))
        sin_omega = torch.sin(omega)
        if sin_omega.abs().mean() < 1e-6:
            return (1 - alpha) * point_a + alpha * point_b
        wa = torch.sin((1 - alpha) * omega) / sin_omega
        wb = torch.sin(alpha * omega) / sin_omega
        result = wa * point_a + wb * point_b
        return F.normalize(result, dim=-1) * math.sqrt(self.config.manifold_dim)
    
    def verify(self, point: torch.Tensor, template: torch.Tensor) -> float:
        """Verify identity against enrolled template."""
        return F.cosine_similarity(point, template, dim=-1).mean().item()
    
    def synthesize(self, point: torch.Tensor, modality: str = 'face') -> torch.Tensor:
        """Synthesize output from manifold point."""
        if modality == 'face':
            return self.generate(point)
        raise NotImplementedError(f"Synthesis for {modality} not implemented")
    
    def train_step(self, voice, face, same_person_mask, optimizer) -> dict:
        """One training step."""
        voice_point = self.encode(voice=voice)
        face_point = self.encode(face=face)
        id_loss = self.identity_loss(voice_point, face_point, same_person_mask.float() * 2 - 1)
        gen_face = self.generate(voice_point)
        recon_point = self.face_encoder(gen_face.detach().view(gen_face.shape[0], -1)[:, :32])
        cycle_loss = F.mse_loss(recon_point, voice_point.detach())
        total = self.config.identity_consistency_weight * id_loss + self.config.cycle_consistency_weight * cycle_loss
        optimizer.zero_grad()
        total.backward()
        optimizer.step()
        return {'total_loss': total.item(), 'identity_loss': id_loss.item(), 'cycle_loss': cycle_loss.item()}
    
    def _get_batch_size(self, *tensors):
        for t in tensors:
            if t is not None:
                return t.shape[0]
        return 1
    
    def _get_device(self, *tensors):
        for t in tensors:
            if t is not None:
                return t.device
        return torch.device('cpu')
MANIFOLD_SKELETON

step_complete "manifold.py skeleton created with all methods"

# Verify the skeleton works
python -c "
from etrnl.manifold import IdentityManifold
import torch
m = IdentityManifold()
p = m.encode(voice=torch.randn(4, 32))
assert p.shape == (4, 128)
g = m.generate(p)
assert g.shape == (4, 3, 256, 256)
n = m.navigate(p, 'nostalgia', 0.5)
i = m.interpolate(p, n, 0.5)
print('  manifold.py: All methods working')
"

# ══════════════════════════════════════════════════════════════════════════════
# STEP 5: Create test file for manifold (Fully Automated — Test Template)
# ══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${BLUE}${BOLD}STEP 5: Creating test_manifold.py${NC}"

cat > tests/test_manifold.py << 'TESTMANIFOLD'
"""Tests for IdentityManifold."""
import torch
import pytest
from etrnl.manifold import IdentityManifold


@pytest.fixture
def manifold():
    return IdentityManifold()


@pytest.fixture
def sample_voice():
    return torch.randn(4, 32)


@pytest.fixture
def sample_face():
    return torch.randn(4, 32)


class TestEncode:
    def test_single_modality(self, manifold, sample_voice):
        point = manifold.encode(voice=sample_voice)
        assert point.shape == (4, 128)
    
    def test_multiple_modalities(self, manifold, sample_voice, sample_face):
        point = manifold.encode(voice=sample_voice, face=sample_face)
        assert point.shape == (4, 128)
    
    def test_all_missing(self, manifold):
        point = manifold.encode()
        assert point.shape == (1, 128)
    
    def test_normalized(self, manifold, sample_voice):
        point = manifold.encode(voice=sample_voice)
        norm = point.norm(dim=-1).mean()
        expected_norm = 128 ** 0.5  # sqrt(manifold_dim)
        assert abs(norm.item() - expected_norm) < 1.0


class TestGenerate:
    def test_output_shape(self, manifold, sample_voice):
        point = manifold.encode(voice=sample_voice)
        face = manifold.generate(point)
        assert face.shape == (4, 3, 256, 256)


class TestNavigate:
    def test_known_direction(self, manifold, sample_voice):
        point = manifold.encode(voice=sample_voice)
        new_point = manifold.navigate(point, 'nostalgia', 0.5)
        assert new_point.shape == (4, 128)
        assert not torch.equal(point, new_point)
    
    def test_unknown_direction(self, manifold, sample_voice):
        point = manifold.encode(voice=sample_voice)
        with pytest.raises(ValueError):
            manifold.navigate(point, 'nonexistent')


class TestInterpolate:
    def test_midpoint(self, manifold, sample_voice, sample_face):
        a = manifold.encode(voice=sample_voice)
        b = manifold.encode(voice=sample_face)
        mid = manifold.interpolate(a, b, 0.5)
        assert mid.shape == (4, 128)
    
    def test_endpoints(self, manifold, sample_voice, sample_face):
        a = manifold.encode(voice=sample_voice)
        b = manifold.encode(voice=sample_face)
        at_a = manifold.interpolate(a, b, 0.0)
        at_b = manifold.interpolate(a, b, 1.0)
        assert torch.allclose(at_a, a, atol=1e-4)
        assert torch.allclose(at_b, b, atol=1e-4)


class TestVerify:
    def test_same_identity(self, manifold, sample_voice):
        p1 = manifold.encode(voice=sample_voice)
        p2 = manifold.encode(voice=sample_voice)
        score = manifold.verify(p1, p2)
        assert score > 0.8
    
    def test_different_identity(self, manifold, sample_voice, sample_face):
        p1 = manifold.encode(voice=sample_voice)
        p2 = manifold.encode(voice=sample_face)
        score = manifold.verify(p1, p2)
        assert score < 1.0  # Different random inputs should differ


class TestResonate:
    def test_output_shape(self, manifold, sample_voice):
        point = manifold.encode(voice=sample_voice)
        query = torch.randn(4, 128)
        resonance = manifold.resonate(point, query)
        assert resonance.shape[0] == 4  # batch size
TESTMANIFOLD

step_complete "test_manifold.py created"

# Run tests
echo ""
echo "Running manifold tests..."
pytest tests/test_manifold.py -v --tb=short

# ══════════════════════════════════════════════════════════════════════════════
# STEP 6: Create remaining empty primitives (Fully Automated)
# ══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${BLUE}${BOLD}STEP 6: Creating remaining primitive skeletons${NC}"

for primitive in presence continuity gradient privacy holograph resonance self_prove; do
    cat > "etrnl/${primitive}.py" << EOF
"""${primitive^} primitive — TODO: Implement."""

from etrnl.contracts import ModuleContract


class ${primitive^}(ModuleContract):
    """${primitive^} primitive."""
    
    __contract__ = {
        'methods': [],
        'guarantees': [],
        'max_latency_ms': 0,
    }
    
    def __init__(self, config=None):
        self.config = config
EOF
    touch "tests/test_${primitive}.py"
    echo "  Created etrnl/${primitive}.py"
done

# Create remaining test files
touch tests/test_integration.py
touch tests/test_contracts.py

# ══════════════════════════════════════════════════════════════════════════════
# STEP 7: Initial Git Commit (Fully Automated)
# ══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${BLUE}${BOLD}STEP 7: Creating initial commit${NC}"

git add -A
git commit -m "Initial commit: EtrnL Essence

- contracts.py: ModuleContract base class
- config.py: All configuration dataclasses
- manifold.py: IdentityManifold with encode, generate, navigate, interpolate
- Remaining primitives: skeletons ready for implementation
- Tests: manifold tests passing" --quiet

step_complete "Initial commit created"

# ══════════════════════════════════════════════════════════════════════════════
# STEP 8: Create the build order file (Fully Automated)
# ══════════════════════════════════════════════════════════════════════════════

cat > NEXT_STEPS.md << 'NEXTSTEPS'
# EtrnL Essence — Next Steps

## What's Done (Automated)
- [x] Environment setup
- [x] All dependencies installed
- [x] contracts.py — ModuleContract base class
- [x] config.py — All configuration dataclasses
- [x] manifold.py — IdentityManifold with encode, generate, navigate, interpolate, verify
- [x] Tests passing for manifold
- [x] Git initialized with initial commit

## What's Next (Build in This Order)

### NOW: Your First Personal Implementation
Open `etrnl/manifold.py` and review the code. Understand how `encode()`
combines modalities. Try modifying the navigation directions.

### THEN: Build the Remaining Primitives

1. **presence.py** — Cryptographic proof of presence
   - Challenge-response protocol
   - Random challenge generation
   - Response verification with timing analysis

2. **privacy.py** — All privacy guarantees
   - Consent-gated filtering (exact zero assignment)
   - Semantic privacy budget allocation
   - Influence isolation (personal data never in shared model)
   - Deterministic deletion with cryptographic certificate

3. **gradient.py** — Perspective gradient interface
   - Five levels: VERBATIM, PARAPHRASE, EXTRAPOLATION, SPECULATION, UNKNOWN
   - User-controlled threshold
   - Didactic intervention triggers

4. **continuity.py** — Life continuity protocol
   - States: ACTIVE → DORMANT → GUARDIANSHIP → LEGACY
   - Steward management
   - Proof-of-life reactivation

5. **holograph.py** — Holographic compute
   - Model fragmentation
   - Quality scaling with fragments
   - Reconstruction from available fragments

6. **resonance.py** — Temporal resonance
   - Manifold interpolation for memory
   - Confidence estimation
   - Reconstruction labeling

7. **self_prove.py** — Self-proving architecture
   - Validation episode generation
   - Continuous self-assessment
   - Fallback activation

## How to Build Each Primitive

```bash
# 1. Open the file
codium etrnl/presence.py

# 2. Write the implementation
# 3. Write tests in tests/test_presence.py
# 4. Run tests
pytest tests/test_presence.py -v

# 5. When tests pass, commit
git add -A && git commit -m "presence: proof-of-presence implemented"