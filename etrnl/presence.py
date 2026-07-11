import os
import time
import hashlib
from etrnl.contracts import ModuleContract


class ProofOfPresence(ModuleContract):
    __contract__ = {
        "methods": ["issue_challenge", "verify_response", "attest"],
        "guarantees": ["challenge_is_random", "replay_attack_impossible"],
        "max_latency_ms": 30000,
    }

    def __init__(self, config=None):
        self.config = config
        self.active_challenges = {}
        self.phrases = [
            "Say: EtrnL verifies identity {code}",
            "Speak: My voice is my proof {code}",
            "Repeat: Present and authentic {code}",
        ]
        self.expressions = [
            "smile",
            "raise eyebrows",
            "look left",
            "look right",
            "nod",
            "blink twice",
            "tilt head",
        ]

    def issue_challenge(self, session_id):
        code = os.urandom(4).hex()
        c = {
            "session_id": session_id,
            "code": code,
            "phrase": self.phrases[hash(code) % len(self.phrases)].format(code=code),
            "expression": self.expressions[hash(code + "e") % len(self.expressions)],
            "issued_at": time.time(),
            "expires_at": time.time() + 30,
            "nonce": os.urandom(16).hex(),
        }
        self.active_challenges[session_id] = c
        return c

    def verify_response(
        self, session_id, spoken_text, expression_detected, response_time_ms
    ):
        c = self.active_challenges.get(session_id)
        if not c:
            return {"passed": False, "reason": "no_active_challenge"}
        if time.time() > c["expires_at"]:
            del self.active_challenges[session_id]
            return {"passed": False, "reason": "expired"}
        if spoken_text.strip().lower() != c["code"].lower():
            return {"passed": False, "reason": "code_mismatch"}
        if expression_detected != c["expression"]:
            return {"passed": False, "reason": "expression_mismatch"}
        if response_time_ms < 500:
            return {"passed": False, "reason": "too_fast"}
        if response_time_ms > 15000:
            return {"passed": False, "reason": "too_slow"}
        del self.active_challenges[session_id]
        return {"passed": True, "session_id": session_id}

    def attest(self, session_id):
        return {
            "session_id": session_id,
            "attested_at": time.time(),
            "signature": hashlib.blake2b(
                f"{session_id}:{time.time()}".encode()
            ).hexdigest(),
        }
