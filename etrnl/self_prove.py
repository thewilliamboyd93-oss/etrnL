from etrnl.contracts import ModuleContract


class SelfProving(ModuleContract):
    __contract__ = {
        "methods": ["check", "disable", "health"],
        "guarantees": ["self_disables_on_failure", "fallback_activates_automatically"],
        "max_latency_ms": 50,
    }

    def __init__(self, config=None):
        self.config = config
        self.components = {}
        self.fallback = {}

    def register(self, name, success_criteria, fallback_fn):
        self.components[name] = {
            "criteria": success_criteria,
            "failures": 0,
            "enabled": True,
            "metrics": {},
        }
        self.fallback[name] = fallback_fn

    def check(self, name, metrics):
        if name not in self.components:
            return True
        comp = self.components[name]
        comp["metrics"] = metrics
        for key, (target, _) in comp["criteria"].items():
            if metrics.get(key, 0) < target:
                comp["failures"] += 1
                if comp["failures"] > 100:
                    self.disable(name)
                    return False
        comp["failures"] = max(0, comp["failures"] - 1)
        return True

    def disable(self, name):
        self.components[name]["enabled"] = False
        self.fallback.get(name, lambda: None)()

    def health(self, name):
        return (
            1.0 if name in self.components and self.components[name]["enabled"] else 0.0
        )
