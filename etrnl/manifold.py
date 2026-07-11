# etrnl/manifold.py
"""IDENTITY MANIFOLD — The central primitive. Everything flows from here."""

import torch
import torch.nn as nn
import torch.nn.functional as F
from typing import Optional
import math

from etrnl.contracts import ModuleContract
from etrnl.config import ManifoldConfig


class IdentityManifold(nn.Module, ModuleContract):
    """
    The central primitive. A 128-dimensional learned space where
    encoding, generation, memory, and navigation are the same operation.

    Contract:
        methods: encode, generate, navigate, resonate, interpolate, verify
        guarantees: manifold_point_is_irreversible, cross_modal_cycle_consistency
        max_latency_ms: 150
    """

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

        # The manifold origin point
        self.origin = nn.Parameter(torch.zeros(1, dim))

        # Modality encoders — project any modality into the manifold
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

        # Learned embeddings for missing modalities
        self.missing_voice = nn.Parameter(torch.randn(1, dim))
        self.missing_face = nn.Parameter(torch.randn(1, dim))
        self.missing_text = nn.Parameter(torch.randn(1, dim))
        self.missing_context = nn.Parameter(torch.randn(1, dim))

        # Generator — reads directly from the manifold (no mapper needed)
        self.generator = nn.Sequential(
            nn.Linear(dim, 256), nn.LayerNorm(256), nn.GELU(),
            nn.Linear(256, 512), nn.LayerNorm(512), nn.GELU(),
            nn.Linear(512, 3 * 256 * 256),
        )

        # Navigation directions — learned emotional/identity axes
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

        # Loss function for identity consistency
        self.identity_loss = nn.CosineEmbeddingLoss()

    # ── Helpers ──────────────────────────────────────────────────────

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

    # ── Core Methods ─────────────────────────────────────────────────

    def encode(
        self,
        voice: Optional[torch.Tensor] = None,
        face: Optional[torch.Tensor] = None,
        text: Optional[torch.Tensor] = None,
        context: Optional[torch.Tensor] = None,
    ) -> torch.Tensor:
        """
        Encode any combination of modalities into the manifold.

        Missing modalities use learned embeddings.
        Multiple modalities are combined via weighted average.

        Returns: (batch_size, manifold_dim) manifold point
        """
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

        weights_tensor = torch.tensor(weights, device=device)
        weights_tensor = weights_tensor / (weights_tensor.sum() + 1e-8)
        stacked = torch.stack(points, dim=0)
        point = (stacked * weights_tensor.view(-1, 1, 1)).sum(dim=0)
        return F.normalize(point, dim=-1) * math.sqrt(self.config.manifold_dim)

    def generate(self, manifold_point: torch.Tensor) -> torch.Tensor:
        """
        Generate a face image directly from a manifold point.
        No mapper needed — the manifold IS the latent space.

        Returns: (batch_size, 3, 256, 256) face image
        """
        raw = self.generator(manifold_point)
        return raw.view(manifold_point.shape[0], 3, 256, 256)

    def navigate(
        self,
        point: torch.Tensor,
        direction: str,
        magnitude: float = 0.5,
    ) -> torch.Tensor:
        """
        Navigate within the manifold along a learned direction.

        Args:
            point: Current manifold point
            direction: One of 'nostalgia', 'curiosity', 'sadness',
                       'warmth', 'humor', 'formality', 'energy',
                       'reflectiveness'
            magnitude: How far to move (0.0 to 1.0)

        Returns: New manifold point after navigation
        """
        if direction not in self.directions:
            raise ValueError(
                f"Unknown direction: {direction}. "
                f"Available: {list(self.directions.keys())}"
            )
        new_point = point + magnitude * self.directions[direction]
        return F.normalize(new_point, dim=-1) * math.sqrt(self.config.manifold_dim)

    def resonate(
        self,
        point: torch.Tensor,
        query: torch.Tensor,
    ) -> torch.Tensor:
        """
        Memory as resonance. The manifold point resonates with a query
        to surface relevant patterns.

        Returns: Similarity scores between point and query
        """
        return F.cosine_similarity(
            point.unsqueeze(1), query.unsqueeze(0), dim=-1
        )

    def interpolate(
        self,
        point_a: torch.Tensor,
        point_b: torch.Tensor,
        alpha: float = 0.5,
    ) -> torch.Tensor:
        """
        Spherical linear interpolation between two manifold points.
        Used for temporal resonance — reconstructing unrecorded periods.

        Args:
            point_a: Earlier known point
            point_b: Later known point
            alpha: 0.0 = point_a, 1.0 = point_b, 0.5 = midpoint

        Returns: Interpolated manifold point
        """
        a_norm = F.normalize(point_a, dim=-1)
        b_norm = F.normalize(point_b, dim=-1)
        omega = torch.acos(
            torch.clamp((a_norm * b_norm).sum(dim=-1, keepdim=True), -1.0, 1.0)
        )
        sin_omega = torch.sin(omega)

        if sin_omega.abs().mean() < 1e-6:
            return (1 - alpha) * point_a + alpha * point_b

        wa = torch.sin((1 - alpha) * omega) / sin_omega
        wb = torch.sin(alpha * omega) / sin_omega
        result = wa * point_a + wb * point_b
        return F.normalize(result, dim=-1) * math.sqrt(self.config.manifold_dim)

    def verify(self, point: torch.Tensor, template: torch.Tensor) -> float:
        """
        Verify identity by comparing a manifold point to an enrolled template.

        Returns: Similarity score (0.0 to 1.0)
        """
        return F.cosine_similarity(point, template, dim=-1).mean().item()

    def synthesize(
        self,
        point: torch.Tensor,
        modality: str = 'face',
    ) -> torch.Tensor:
        """
        Synthesize output from a manifold point.

        Args:
            point: Manifold point
            modality: 'face' (more modalities added later)

        Returns: Generated output for the requested modality
        """
        if modality == 'face':
            return self.generate(point)
        raise NotImplementedError(
            f"Synthesis for '{modality}' not yet implemented"
        )

    # ── Training ─────────────────────────────────────────────────────

    def train_step(
        self,
        voice: torch.Tensor,
        face: torch.Tensor,
        same_person_mask: torch.Tensor,
        optimizer: torch.optim.Optimizer,
    ) -> dict:
        """
        One training step.

        Losses:
            - Identity consistency: same person's voice/face map nearby
            - Cross-modal cycle: voice → face → voice should return

        Returns: Dict with loss values
        """
        voice_point = self.encode(voice=voice)
        face_point = self.encode(face=face)

        # Identity consistency loss
        id_loss = self.identity_loss(
            voice_point, face_point,
            same_person_mask.float() * 2 - 1
        )

        # Cross-modal cycle consistency
        gen_face = self.generate(voice_point)
        recon_point = self.face_encoder(
            gen_face.detach().view(gen_face.shape[0], -1)[:, :32]
        )
        cycle_loss = F.mse_loss(recon_point, voice_point.detach())

        # Combined loss
        total = (
            self.config.identity_consistency_weight * id_loss
            + self.config.cycle_consistency_weight * cycle_loss
        )

        optimizer.zero_grad()
        total.backward()
        optimizer.step()

        return {
            'total_loss': total.item(),
            'identity_loss': id_loss.item(),
            'cycle_loss': cycle_loss.item(),
        }