import torch
from etrnl.manifold import IdentityManifold
from etrnl.presence import ProofOfPresence
from etrnl.privacy import Privacy
from etrnl.gradient import PerspectiveGradient
from etrnl.config import ConsentProfile


def test_full_pipeline():
    m = IdentityManifold()
    p = m.encode(voice=torch.randn(1, 32))
    assert p.shape == (1, 128)


def test_presence_and_privacy():
    pop = ProofOfPresence()
    priv = Privacy()
    c = pop.issue_challenge("test")
    assert len(c["code"]) == 8
    f = priv.filter(torch.randn(1, 64), ConsentProfile.all_allowed())
    assert f.shape == (1, 64)


def test_gradient_and_continuity():
    from etrnl.continuity import LifeContinuity

    g = PerspectiveGradient()
    lc = LifeContinuity()
    r = g.respond("Test", 0.97)
    assert r["level"] == 1
    s = lc.check("p1")
    assert s["state"] in ["ACTIVE", "DORMANT", "GUARDIANSHIP"]
