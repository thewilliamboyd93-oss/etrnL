import time
import pytest
from etrnl.continuity import LifeContinuity


@pytest.fixture
def lc():
    return LifeContinuity()


def test_active(lc):
    assert lc.check("p1", time.time())["state"] == "ACTIVE"


def test_dormant(lc):
    assert lc.check("p2", time.time() - 40 * 86400)["state"] == "DORMANT"


def test_guardian(lc):
    assert lc.check("p3", time.time() - 100 * 86400)["state"] == "GUARDIANSHIP"


def test_legacy_needs_stewards(lc):
    assert not lc.transition("p4", "LEGACY")["success"]


def test_legacy_with_stewards(lc):
    assert lc.transition("p4", "LEGACY", [True, True, True])["success"]


def test_reactivate(lc):
    lc.check("p5", time.time() - 100 * 86400)
    assert lc.reactivate("p5")["state"] == "ACTIVE"
