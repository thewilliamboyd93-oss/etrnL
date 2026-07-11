import torch
from etrnl.contracts import ModuleContract


class TemporalResonance(ModuleContract):
    __contract__ = {
        "methods": ["reconstruct", "confidence"],
        "guarantees": [
            "always_labeled_as_reconstruction",
            "confidence_scales_with_anchor_distance",
        ],
        "max_latency_ms": 500,
    }

    def __init__(self, config=None):
        self.config = config

    def reconstruct(self, point_before, point_after, alpha=0.5, context=None):
        reconstructed = (1 - alpha) * point_before + alpha * point_after
        distance = torch.norm(point_after - point_before).item()
        conf = max(0.2, 1.0 - distance / 10.0)
        return {
            "point": reconstructed,
            "confidence": conf,
            "alpha": alpha,
            "disclaimer": f"RECONSTRUCTION (confidence: {conf:.0%})",
            "is_reconstruction": True,
        }

    def confidence(self, anchor_distance):
        return max(0.2, 1.0 - anchor_distance / 10.0)
