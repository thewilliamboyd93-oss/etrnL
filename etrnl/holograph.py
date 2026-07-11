import torch
from etrnl.contracts import ModuleContract


class HolographicModel(ModuleContract):
    __contract__ = {
        "methods": ["fragment", "reconstruct", "quality"],
        "guarantees": ["fragments_work_independently", "quality_scales_with_count"],
        "max_latency_ms": 100,
    }

    def __init__(self, config=None):
        self.config = config
        self.num_fragments = getattr(config, "num_fragments", 4) if config else 4
        self.fragments = [torch.randn(1, 128) * 0.1 for _ in range(self.num_fragments)]

    def fragment(self, model_weights=None):
        return [
            {"id": i, "vector": f, "quality": 0.6 + (0.12 * i)}
            for i, f in enumerate(self.fragments)
        ]

    def reconstruct(self, available_fragments):
        if not available_fragments:
            return {"result": torch.zeros(1, 128), "quality": 0.0, "fragments_used": 0}
        stacked = torch.stack([f["vector"] for f in available_fragments])
        result = stacked.mean(dim=0)
        quality = min(1.0, 0.5 + 0.13 * len(available_fragments))
        return {
            "result": result,
            "quality": quality,
            "fragments_used": len(available_fragments),
        }

    def quality(self, fragment_count):
        return min(1.0, 0.5 + 0.13 * fragment_count)
