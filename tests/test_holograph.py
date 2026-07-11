import pytest
from etrnl.holograph import HolographicModel


@pytest.fixture
def hm():
    return HolographicModel()


def test_fragments(hm):
    assert len(hm.fragment()) == 4


def test_single_quality(hm):
    f = hm.fragment()
    assert hm.reconstruct([f[0]])["quality"] > 0.5


def test_all_quality(hm):
    assert hm.reconstruct(hm.fragment())["quality"] > 0.9


def test_scaling(hm):
    assert hm.quality(1) < hm.quality(4)
