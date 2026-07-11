import pytest
from etrnl.gradient import PerspectiveGradient


@pytest.fixture
def g():
    return PerspectiveGradient()


def test_verbatim(g):
    assert g.respond("Hi", 0.97)["level"] == 1


def test_unknown(g):
    assert g.respond("?", 0.1)["level"] == 5


def test_threshold(g):
    g.set_threshold(1)
    assert g.respond("X", 0.85)["level"] == 5


def test_levels(g):
    assert g.get_level(0.96) == 1
    assert g.get_level(0.50) == 4
    assert g.get_level(0.01) == 5
