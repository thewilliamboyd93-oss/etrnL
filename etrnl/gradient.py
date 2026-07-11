from etrnl.contracts import ModuleContract


class PerspectiveGradient(ModuleContract):
    __contract__ = {
        "methods": ["respond", "get_level", "set_threshold"],
        "guarantees": ["always_discloses_level", "threshold_respected"],
        "max_latency_ms": 10,
    }
    LEVELS = {
        1: {
            "name": "VERBATIM",
            "min_confidence": 0.95,
            "color": "#00ff88",
            "description": "Exact words the person said",
        },
        2: {
            "name": "PARAPHRASE",
            "min_confidence": 0.80,
            "color": "#88ff00",
            "description": "Synthesis of consistent sources",
        },
        3: {
            "name": "EXTRAPOLATION",
            "min_confidence": 0.60,
            "color": "#ffaa00",
            "description": "Inference from patterns",
        },
        4: {
            "name": "SPECULATION",
            "min_confidence": 0.40,
            "color": "#ff6600",
            "description": "Possible view, no direct evidence",
        },
        5: {
            "name": "UNKNOWN",
            "min_confidence": 0.00,
            "color": "#ff0000",
            "description": "No evidence available",
        },
    }

    def __init__(self, config=None):
        self.config = config
        self.threshold = getattr(config, "default_user_threshold", 2) if config else 2

    def respond(self, content, confidence, sources=None):
        level = 5
        for lvl in range(1, 6):
            if confidence >= self.LEVELS[lvl]["min_confidence"]:
                level = lvl
                break
        if level > self.threshold:
            return {
                "text": "I don't have enough information to answer that.",
                "level": 5,
                "level_name": "UNKNOWN",
                "confidence": 0.0,
            }
        return {
            "text": content,
            "level": level,
            "level_name": self.LEVELS[level]["name"],
            "confidence": confidence,
            "color": self.LEVELS[level]["color"],
            "sources": sources or [],
            "disclaimer": self.LEVELS[level]["description"],
        }

    def get_level(self, confidence):
        for lvl in range(1, 6):
            if confidence >= self.LEVELS[lvl]["min_confidence"]:
                return lvl
        return 5

    def set_threshold(self, level):
        self.threshold = max(1, min(5, level))
