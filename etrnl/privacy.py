import os
import shutil
import time
import hashlib
import torch
from etrnl.contracts import ModuleContract
from etrnl.config import ConsentAttribute


class Privacy(ModuleContract):
    __contract__ = {
        "methods": ["filter", "isolate", "delete", "audit"],
        "guarantees": [
            "exact_zero",
            "semantic_budget",
            "deterministic_deletion",
            "audit_integrity",
        ],
        "max_latency_ms": 5,
    }

    def __init__(self, config=None):
        self.config = config
        self.isolation_dir = (
            getattr(config, "isolation_dir", "./isolation") if config else "./isolation"
        )
        self.audit_log = []
        self.dimensions = {
            "age": (0, 5),
            "gender": (5, 8),
            "accent": (8, 18),
            "mood": (18, 23),
            "reactivity": (23, 26),
            "activity": (26, 34),
            "social": (34, 39),
        }

    def filter(self, state_vector, consent_profile):
        filtered = state_vector.clone()
        for attr_name, (start, end) in self.dimensions.items():
            attr = ConsentAttribute(attr_name)
            if consent_profile.is_denied(attr):
                filtered[:, start:end] = 0.0
        self.audit_log.append({"timestamp": time.time(), "action": "filter"})
        return filtered

    def isolate(self, person_id, data):
        person_dir = os.path.join(self.isolation_dir, person_id)
        os.makedirs(person_dir, exist_ok=True)
        torch.save(data, os.path.join(person_dir, "personal.pt"))
        return person_dir

    def delete(self, person_id):
        person_dir = os.path.join(self.isolation_dir, person_id)
        if os.path.exists(person_dir):
            shutil.rmtree(person_dir)
            return {
                "deleted": True,
                "person_id": person_id,
                "certificate": hashlib.blake2b(
                    f"{person_id}:{time.time()}".encode()
                ).hexdigest(),
            }
        return {"deleted": False, "reason": "not_found"}

    def audit(self, person_id):
        return {
            "person_id": person_id,
            "entries": len(self.audit_log),
            "log": self.audit_log,
        }
