import torch
import pytest
from etrnl.resonance import TemporalResonance


@pytest.fixture
def tr():
    return TemporalResonance()


def test_reconstruct(tr):
    a, b = torch.randn(1, 128), torch.randn(1, 128)
    r = tr.reconstruct(a, b)
    assert r["is_reconstruction"]


def test_confidence_far(tr):
    a = torch.randn(1, 128)
    b = a + torch.randn(1, 128) * 5
    assert tr.confidence(1.0) > tr.confidence(8.0)
