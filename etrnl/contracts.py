"""Interface contracts for EtrnL primitives."""


class ContractViolation(Exception):
    pass


class ModuleContract:
    __contract__ = {"methods": [], "guarantees": [], "max_latency_ms": 0}

    def __init_subclass__(cls, **kwargs):
        super().__init_subclass__(**kwargs)
        cls._verify_contract()

    @classmethod
    def _verify_contract(cls):
        for method_name in cls.__contract__.get("methods", []):
            if not hasattr(cls, method_name):
                raise ContractViolation(f"{cls.__name__} missing method: {method_name}")
