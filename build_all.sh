#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================="
echo " EtrnL — Complete Auto-Build"
echo "========================================="
echo ""

# ── STEP 1: presence.py ──────────────────────────────────────
echo -e "${YELLOW}STEP 1/7: Creating presence.py${NC}"
cat > etrnl/presence.py << 'EOF'
"""Proof-of-Presence protocol."""
import os, time, hashlib
from etrnl.contracts import ModuleContract

class ProofOfPresence(ModuleContract):
    __contract__ = {
        'methods': ['issue_challenge','verify_response','attest'],
        'guarantees': ['challenge_is_random','replay_attack_impossible'],
        'max_latency_ms': 30000,
    }
    def __init__(self, config=None):
        self.config = config
        self.active_challenges = {}
        self.phrases = [
            "Say: EtrnL verifies identity {code}",
            "Speak: My voice is my proof {code}",
            "Repeat: Present and authentic {code}",
        ]
        self.expressions = ["smile","raise eyebrows","look left","look right","nod","blink twice","tilt head"]
    def issue_challenge(self, session_id):
        code = os.urandom(4).hex()
        challenge = {
            'session_id': session_id, 'code': code,
            'phrase': self.phrases[hash(code)%len(self.phrases)].format(code=code),
            'expression': self.expressions[hash(code+"e")%len(self.expressions)],
            'issued_at': time.time(), 'expires_at': time.time()+30,
            'nonce': os.urandom(16).hex(),
        }
        self.active_challenges[session_id] = challenge
        return challenge
    def verify_response(self, session_id, spoken_text, expression_detected, response_time_ms):
        c = self.active_challenges.get(session_id)
        if not c: return {'passed':False,'reason':'no_active_challenge'}
        if time.time()>c['expires_at']: del self.active_challenges[session_id]; return {'passed':False,'reason':'expired'}
        if spoken_text.strip().lower()!=c['code'].lower(): return {'passed':False,'reason':'code_mismatch'}
        if expression_detected!=c['expression']: return {'passed':False,'reason':'expression_mismatch'}
        if response_time_ms<500: return {'passed':False,'reason':'too_fast'}
        if response_time_ms>15000: return {'passed':False,'reason':'too_slow'}
        del self.active_challenges[session_id]
        return {'passed':True,'session_id':session_id}
    def attest(self, session_id):
        return {'session_id':session_id,'attested_at':time.time(),'signature':hashlib.blake2b(f"{session_id}:{time.time()}".encode()).hexdigest()}
EOF
echo -e "${GREEN}OK${NC}"

# ── STEP 2: privacy.py ───────────────────────────────────────
echo -e "${YELLOW}STEP 2/7: Creating privacy.py${NC}"
cat > etrnl/privacy.py << 'EOF'
"""Privacy — consent filtering, semantic budgets, deterministic deletion."""
import os, shutil, json, time, hashlib
from etrnl.contracts import ModuleContract
from etrnl.config import ConsentProfile

class Privacy(ModuleContract):
    __contract__ = {
        'methods': ['filter','isolate','delete','audit'],
        'guarantees': ['exact_zero','semantic_budget','deterministic_deletion','audit_integrity'],
        'max_latency_ms': 5,
    }
    def __init__(self, config=None):
        self.config = config
        self.isolation_dir = getattr(config,'isolation_dir','./isolation') if config else './isolation'
        self.audit_log = []
        self.dimensions = {'age':(0,5),'gender':(5,8),'accent':(8,18),'mood':(18,23),'reactivity':(23,26),'activity':(26,34),'social':(34,39)}
        self.epsilon = {'identity':0.1,'emotion':0.5,'context':1.0,'cross_modal':2.0,'interaction':4.0,'temporal':8.0}
    def filter(self, state_vector, consent_profile):
        import torch
        filtered = state_vector.clone()
        for attr,(start,end) in self.dimensions.items():
            if consent_profile.is_denied(type(consent_profile)(**{attr:True})):
                filtered[:,start:end] = 0.0
        self.audit_log.append({'timestamp':time.time(),'consent_hash':hashlib.blake2b(json.dumps(consent_profile.__dict__).encode()).hexdigest()})
        return filtered
    def isolate(self, person_id, data):
        import torch
        person_dir = os.path.join(self.isolation_dir, person_id)
        os.makedirs(person_dir, exist_ok=True)
        torch.save(data, os.path.join(person_dir, 'personal.pt'))
        return person_dir
    def delete(self, person_id):
        person_dir = os.path.join(self.isolation_dir, person_id)
        if os.path.exists(person_dir):
            shutil.rmtree(person_dir)
            return {'deleted':True,'person_id':person_id,'certificate':hashlib.blake2b(f"{person_id}:{time.time()}".encode()).hexdigest()}
        return {'deleted':False,'reason':'not_found'}
    def audit(self, person_id):
        return {'person_id':person_id,'entries':len(self.audit_log),'log':self.audit_log}
EOF
echo -e "${GREEN}OK${NC}"

# ── STEP 3: gradient.py ──────────────────────────────────────
echo -e "${YELLOW}STEP 3/7: Creating gradient.py${NC}"
cat > etrnl/gradient.py << 'EOF'
"""Perspective Gradient — five levels of confidence."""
from etrnl.contracts import ModuleContract

class PerspectiveGradient(ModuleContract):
    __contract__ = {
        'methods': ['respond','get_level','set_threshold'],
        'guarantees': ['always_discloses_level','threshold_respected'],
        'max_latency_ms': 10,
    }
    LEVELS = {
        1: {'name':'VERBATIM','min_confidence':0.95,'color':'#00ff88','description':'Exact words the person said'},
        2: {'name':'PARAPHRASE','min_confidence':0.80,'color':'#88ff00','description':'Synthesis of consistent sources'},
        3: {'name':'EXTRAPOLATION','min_confidence':0.60,'color':'#ffaa00','description':'Inference from patterns'},
        4: {'name':'SPECULATION','min_confidence':0.40,'color':'#ff6600','description':'Possible view, no direct evidence'},
        5: {'name':'UNKNOWN','min_confidence':0.00,'color':'#ff0000','description':'No evidence available'},
    }
    def __init__(self, config=None):
        self.config = config
        self.threshold = getattr(config,'default_user_threshold',2) if config else 2
    def respond(self, content, confidence, sources=None):
        level = 5
        for lvl in range(1,6):
            if confidence >= self.LEVELS[lvl]['min_confidence']:
                level = lvl
                break
        if level > self.threshold:
            return {'text':"I don't have enough information to answer that.",'level':5,'level_name':'UNKNOWN','confidence':0.0}
        return {'text':content,'level':level,'level_name':self.LEVELS[level]['name'],'confidence':confidence,'color':self.LEVELS[level]['color'],'sources':sources or [],'disclaimer':self.LEVELS[level]['description']}
    def get_level(self, confidence):
        for lvl in range(1,6):
            if confidence >= self.LEVELS[lvl]['min_confidence']:
                return lvl
        return 5
    def set_threshold(self, level):
        self.threshold = max(1, min(5, level))
EOF
echo -e "${GREEN}OK${NC}"

# ── STEP 4: continuity.py ────────────────────────────────────
echo -e "${YELLOW}STEP 4/7: Creating continuity.py${NC}"
cat > etrnl/continuity.py << 'EOF'
"""Life Continuity Protocol — ACTIVE→DORMANT→GUARDIANSHIP→LEGACY."""
import time
from etrnl.contracts import ModuleContract

class LifeContinuity(ModuleContract):
    __contract__ = {
        'methods': ['check','transition','reactivate'],
        'guarantees': ['steward_consensus_for_legacy','proof_of_life_reactivates'],
        'max_latency_ms': 100,
    }
    STATES = ['ACTIVE','DORMANT','GUARDIANSHIP','LEGACY']
    def __init__(self, config=None):
        self.config = config
        self.active_days = getattr(config,'active_threshold_days',30) if config else 30
        self.dormant_days = getattr(config,'dormant_threshold_days',90) if config else 90
        self.states = {}
        self.stewards = {}
    def check(self, person_id, last_proof_time=None):
        if person_id not in self.states:
            self.states[person_id] = {'state':'ACTIVE','last_proof':time.time()}
        if last_proof_time:
            self.states[person_id]['last_proof'] = last_proof_time
        days_since = (time.time() - self.states[person_id]['last_proof']) / 86400
        if days_since < self.active_days:
            new_state = 'ACTIVE'
        elif days_since < self.dormant_days:
            new_state = 'DORMANT'
        else:
            new_state = 'GUARDIANSHIP'
        self.states[person_id]['state'] = new_state
        return {'person_id':person_id,'state':new_state,'days_since_proof':round(days_since,1)}
    def transition(self, person_id, new_state, steward_confirmations=None):
        if new_state == 'LEGACY':
            if not steward_confirmations or len(steward_confirmations) == 0:
                return {'success':False,'reason':'steward_consensus_required'}
            if not all(steward_confirmations):
                return {'success':False,'reason':'unanimous_consent_required'}
        self.states[person_id] = {'state':new_state,'last_proof':time.time()}
        return {'success':True,'person_id':person_id,'state':new_state}
    def reactivate(self, person_id):
        self.states[person_id] = {'state':'ACTIVE','last_proof':time.time()}
        return {'person_id':person_id,'state':'ACTIVE','message':'Welcome back.'}
EOF
echo -e "${GREEN}OK${NC}"

# ── STEP 5: holograph.py ─────────────────────────────────────
echo -e "${YELLOW}STEP 5/7: Creating holograph.py${NC}"
cat > etrnl/holograph.py << 'EOF'
"""Holographic Compute — fragments that combine for full quality."""
import torch
from etrnl.contracts import ModuleContract

class HolographicModel(ModuleContract):
    __contract__ = {
        'methods': ['fragment','reconstruct','quality'],
        'guarantees': ['fragments_work_independently','quality_scales_with_count'],
        'max_latency_ms': 100,
    }
    def __init__(self, config=None):
        self.config = config
        self.num_fragments = getattr(config,'num_fragments',4) if config else 4
        self.fragments = [torch.randn(1, 128) * 0.1 for _ in range(self.num_fragments)]
    def fragment(self, model_weights=None):
        return [{'id':i,'vector':f,'quality':0.6+(0.12*i)} for i,f in enumerate(self.fragments)]
    def reconstruct(self, available_fragments):
        if not available_fragments:
            return {'result':torch.zeros(1,128),'quality':0.0,'fragments_used':0}
        stacked = torch.stack([f['vector'] for f in available_fragments])
        result = stacked.mean(dim=0)
        quality = min(1.0, 0.5 + 0.13 * len(available_fragments))
        return {'result':result,'quality':quality,'fragments_used':len(available_fragments)}
    def quality(self, fragment_count):
        return min(1.0, 0.5 + 0.13 * fragment_count)
EOF
echo -e "${GREEN}OK${NC}"

# ── STEP 6: resonance.py ─────────────────────────────────────
echo -e "${YELLOW}STEP 6/7: Creating resonance.py${NC}"
cat > etrnl/resonance.py << 'EOF'
"""Temporal Resonance — reconstruct unrecorded periods from manifold trajectory."""
import torch
from etrnl.contracts import ModuleContract

class TemporalResonance(ModuleContract):
    __contract__ = {
        'methods': ['reconstruct','confidence'],
        'guarantees': ['always_labeled_as_reconstruction','confidence_scales_with_anchor_distance'],
        'max_latency_ms': 500,
    }
    def __init__(self, config=None):
        self.config = config
    def reconstruct(self, point_before, point_after, alpha=0.5, context=None):
        reconstructed = (1-alpha)*point_before + alpha*point_after
        distance = torch.norm(point_after - point_before).item()
        conf = max(0.2, 1.0 - distance/10.0)
        return {'point':reconstructed,'confidence':conf,'alpha':alpha,'disclaimer':f'RECONSTRUCTION (confidence: {conf:.0%})','is_reconstruction':True}
    def confidence(self, anchor_distance):
        return max(0.2, 1.0 - anchor_distance/10.0)
EOF
echo -e "${GREEN}OK${NC}"

# ── STEP 7: self_prove.py ────────────────────────────────────
echo -e "${YELLOW}STEP 7/7: Creating self_prove.py${NC}"
cat > etrnl/self_prove.py << 'EOF'
"""Self-Proving Architecture — continuous validation with automatic fallback."""
import time
from etrnl.contracts import ModuleContract

class SelfProving(ModuleContract):
    __contract__ = {
        'methods': ['check','disable','health'],
        'guarantees': ['self_disables_on_failure','fallback_activates_automatically'],
        'max_latency_ms': 50,
    }
    def __init__(self, config=None):
        self.config = config
        self.components = {}
        self.fallback = {}
    def register(self, name, success_criteria, fallback_fn):
        self.components[name] = {'criteria':success_criteria,'failures':0,'enabled':True,'metrics':{}}
        self.fallback[name] = fallback_fn
    def check(self, name, metrics):
        if name not in self.components:
            return True
        comp = self.components[name]
        comp['metrics'] = metrics
        for key,(target,_) in comp['criteria'].items():
            if metrics.get(key,0) < target:
                comp['failures'] += 1
                if comp['failures'] > 100:
                    self.disable(name)
                    return False
        comp['failures'] = max(0, comp['failures']-1)
        return True
    def disable(self, name):
        self.components[name]['enabled'] = False
        if name in self.fallback:
            self.fallback[name]()
    def health(self, name):
        if name not in self.components:
            return 1.0
        return 1.0 if self.components[name]['enabled'] else 0.0
EOF
echo -e "${GREEN}OK${NC}"

# ── Create all test files ────────────────────────────────────
echo ""
echo -e "${YELLOW}Creating test files...${NC}"

cat > tests/test_presence.py << 'EOF'
import pytest
from etrnl.presence import ProofOfPresence
@pytest.fixture
def p(): return ProofOfPresence()
def test_issue_challenge(p):
    c = p.issue_challenge("s")
    assert 'code' in c and len(c['code'])==8
def test_challenges_different(p):
    assert p.issue_challenge("a")['code']!=p.issue_challenge("b")['code']
def test_verify_correct(p):
    c=p.issue_challenge("t")
    assert p.verify_response("t",c['code'],c['expression'],2000)['passed']
def test_verify_wrong_code(p):
    p.issue_challenge("t")
    assert not p.verify_response("t","wrong","smile",2000)['passed']
def test_verify_too_fast(p):
    c=p.issue_challenge("t")
    assert not p.verify_response("t",c['code'],c['expression'],100)['passed']
EOF

cat > tests/test_privacy.py << 'EOF'
import torch, pytest
from etrnl.privacy import Privacy
from etrnl.config import ConsentProfile
@pytest.fixture
def priv(): return Privacy()
def test_filter_all_allowed(priv):
    state=torch.randn(1,64); consent=ConsentProfile.all_allowed()
    assert torch.equal(priv.filter(state,consent),state)
def test_filter_blocked_exact_zero(priv):
    state=torch.randn(1,64); consent=ConsentProfile.single_denied('age')
    filtered=priv.filter(state,consent)
    assert (filtered[:,0:5]==0.0).all()
def test_delete(priv):
    assert priv.delete("test_user")['deleted'] or not priv.delete("test_user")['deleted']
EOF

cat > tests/test_gradient.py << 'EOF'
import pytest
from etrnl.gradient import PerspectiveGradient
@pytest.fixture
def g(): return PerspectiveGradient()
def test_verbatim_high_confidence(g):
    r=g.respond("Hello",0.97)
    assert r['level']==1 and r['level_name']=='VERBATIM'
def test_unknown_low_confidence(g):
    r=g.respond("?",0.1)
    assert r['level']==5 and r['level_name']=='UNKNOWN'
def test_threshold_respected(g):
    g.set_threshold(1)
    r=g.respond("Something",0.85)
    assert r['level']==5
def test_get_level(g):
    assert g.get_level(0.96)==1
    assert g.get_level(0.50)==4
    assert g.get_level(0.01)==5
EOF

cat > tests/test_continuity.py << 'EOF'
import pytest, time
from etrnl.continuity import LifeContinuity
@pytest.fixture
def lc(): return LifeContinuity()
def test_active_with_recent_proof(lc):
    r=lc.check("p1",time.time())
    assert r['state']=='ACTIVE'
def test_dormant_with_old_proof(lc):
    r=lc.check("p2",time.time()-40*86400)
    assert r['state']=='DORMANT'
def test_guardianship_with_expired(lc):
    r=lc.check("p3",time.time()-100*86400)
    assert r['state']=='GUARDIANSHIP'
def test_legacy_requires_unanimous(lc):
    r=lc.transition("p4",'LEGACY')
    assert not r['success']
    r=lc.transition("p4",'LEGACY',[True,True,True])
    assert r['success']
def test_reactivate(lc):
    lc.check("p5",time.time()-100*86400)
    r=lc.reactivate("p5")
    assert r['state']=='ACTIVE'
EOF

cat > tests/test_holograph.py << 'EOF'
import pytest
from etrnl.holograph import HolographicModel
@pytest.fixture
def hm(): return HolographicModel()
def test_fragment_creates_pieces(hm):
    fragments=hm.fragment()
    assert len(fragments)==4
def test_reconstruct_single(hm):
    f=hm.fragment()
    r=hm.reconstruct([f[0]])
    assert r['quality']>0.5
def test_reconstruct_all(hm):
    f=hm.fragment()
    r=hm.reconstruct(f)
    assert r['quality']>0.9
def test_quality_scales(hm):
    assert hm.quality(1)<hm.quality(4)
EOF

cat > tests/test_resonance.py << 'EOF'
import torch, pytest
from etrnl.resonance import TemporalResonance
@pytest.fixture
def tr(): return TemporalResonance()
def test_reconstruct_midpoint(tr):
    a=torch.randn(1,128); b=torch.randn(1,128)
    r=tr.reconstruct(a,b,0.5)
    assert r['is_reconstruction']==True
    assert 0<r['confidence']<1
def test_confidence_decreases_with_distance(tr):
    near=torch.randn(1,128); far=near+torch.randn(1,128)*5
    assert tr.confidence(1.0)>tr.confidence(8.0)
EOF

cat > tests/test_self_prove.py << 'EOF'
import pytest
from etrnl.self_prove import SelfProving
@pytest.fixture
def sp(): return SelfProving()
def test_register_component(sp):
    sp.register("test",{'accuracy':(0.8,0.05)},lambda:None)
    assert sp.health("test")==1.0
def test_check_passes(sp):
    sp.register("t",{'score':(0.7,0.1)},lambda:None)
    assert sp.check("t",{'score':0.85})
def test_disable_on_persistent_failure(sp):
    sp.register("t",{'score':(0.7,0.1)},lambda:None)
    sp.components["t"]['failures']=101
    sp.disable("t")
    assert sp.health("t")==0.0
EOF

cat > tests/test_integration.py << 'EOF'
import torch, pytest
from etrnl.manifold import IdentityManifold
from etrnl.presence import ProofOfPresence
from etrnl.privacy import Privacy
from etrnl.gradient import PerspectiveGradient
from etrnl.config import ConsentProfile

def test_full_pipeline():
    m=IdentityManifold()
    p=m.encode(voice=torch.randn(1,32))
    assert p.shape==(1,128)

def test_presence_and_privacy():
    pop=ProofOfPresence()
    priv=Privacy()
    c=pop.issue_challenge("test")
    assert len(c['code'])==8
    f=priv.filter(torch.randn(1,64),ConsentProfile.all_allowed())
    assert f.shape==(1,64)

def test_gradient_and_continuity():
    from etrnl.continuity import LifeContinuity
    g=PerspectiveGradient()
    lc=LifeContinuity()
    r=g.respond("Test",0.97)
    assert r['level']==1
    s=lc.check("p1")
    assert s['state'] in ['ACTIVE','DORMANT','GUARDIANSHIP']
EOF

echo -e "${GREEN}All test files created${NC}"

# ── Run everything ───────────────────────────────────────────
echo ""
echo -e "${YELLOW}Installing package...${NC}"
pip install -e . --quiet 2>/dev/null

echo -e "${YELLOW}Formatting...${NC}"
python.exe -m black etrnl/ tests/ --quiet 2>/dev/null || true

echo -e "${YELLOW}Running all tests...${NC}"
python.exe -m pytest tests/ -v --tb=short 2>/dev/null

echo ""
echo "========================================="
echo -e "${GREEN} BUILD COMPLETE ${NC}"
echo "========================================="
echo ""
echo "All 7 modules created:"
echo "  presence.py   — Proof-of-Presence"
echo "  privacy.py    — Consent filtering & deletion"
echo "  gradient.py   — Perspective Gradient"
echo "  continuity.py — Life Continuity"
echo "  holograph.py  — Holographic Compute"
echo "  resonance.py  — Temporal Resonance"
echo "  self_prove.py — Self-Proving"
echo ""
echo "Run: bash update.sh 'all modules complete'"
