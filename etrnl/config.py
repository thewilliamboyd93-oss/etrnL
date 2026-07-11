"""Configuration for EtrnL primitives."""

from dataclasses import dataclass
from enum import Enum


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

    def is_allowed(self, a):
        return getattr(self, a.value)

    def is_denied(self, a):
        return not self.is_allowed(a)

    @classmethod
    def all_allowed(cls):
        return cls()

    @classmethod
    def all_denied(cls):
        return cls(*(False,) * 7)

    @classmethod
    def single_denied(cls, attr):
        p = cls()
        setattr(p, attr, False)
        return p


@dataclass
class ManifoldConfig:
    manifold_dim: int = 128
    identity_consistency_weight: float = 1.0
    cycle_consistency_weight: float = 0.5
