import pytest
from etrnl.self_prove import SelfProving


@pytest.fixture
def sp():
    return SelfProving()


def test_register(sp):
    sp.register("t", {"score": (0.7, 0.1)}, lambda: None)
    assert sp.health("t") == 1.0


def test_check_pass(sp):
    sp.register("t", {"score": (0.7, 0.1)}, lambda: None)
    assert sp.check("t", {"score": 0.85})


def test_disable(sp):
    sp.register("t", {"score": (0.7, 0.1)}, lambda: None)
    sp.components["t"]["failures"] = 101
    sp.disable("t")
    assert sp.health("t") == 0.0
