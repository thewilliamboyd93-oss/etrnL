import time
from etrnl.contracts import ModuleContract


class LifeContinuity(ModuleContract):
    __contract__ = {
        "methods": ["check", "transition", "reactivate"],
        "guarantees": ["steward_consensus_for_legacy", "proof_of_life_reactivates"],
        "max_latency_ms": 100,
    }
    STATES = ["ACTIVE", "DORMANT", "GUARDIANSHIP", "LEGACY"]

    def __init__(self, config=None):
        self.config = config
        self.active_days = (
            getattr(config, "active_threshold_days", 30) if config else 30
        )
        self.dormant_days = (
            getattr(config, "dormant_threshold_days", 90) if config else 90
        )
        self.states = {}
        self.stewards = {}

    def check(self, person_id, last_proof_time=None):
        if person_id not in self.states:
            self.states[person_id] = {"state": "ACTIVE", "last_proof": time.time()}
        if last_proof_time:
            self.states[person_id]["last_proof"] = last_proof_time
        days_since = (time.time() - self.states[person_id]["last_proof"]) / 86400
        if days_since < self.active_days:
            new_state = "ACTIVE"
        elif days_since < self.dormant_days:
            new_state = "DORMANT"
        else:
            new_state = "GUARDIANSHIP"
        self.states[person_id]["state"] = new_state
        return {
            "person_id": person_id,
            "state": new_state,
            "days_since_proof": round(days_since, 1),
        }

    def transition(self, person_id, new_state, steward_confirmations=None):
        if new_state == "LEGACY":
            if not steward_confirmations or len(steward_confirmations) == 0:
                return {"success": False, "reason": "steward_consensus_required"}
            if not all(steward_confirmations):
                return {"success": False, "reason": "unanimous_consent_required"}
        self.states[person_id] = {"state": new_state, "last_proof": time.time()}
        return {"success": True, "person_id": person_id, "state": new_state}

    def reactivate(self, person_id):
        self.states[person_id] = {"state": "ACTIVE", "last_proof": time.time()}
        return {"person_id": person_id, "state": "ACTIVE", "message": "Welcome back."}
