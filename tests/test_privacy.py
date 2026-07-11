import torch
import pytest
from etrnl.privacy import Privacy
from etrnl.config import ConsentProfile


@pytest.fixture
def priv():
    return Privacy()


def test_allow_all(priv):
    s = torch.randn(1, 64)
    assert torch.equal(priv.filter(s, ConsentProfile.all_allowed()), s)


def test_block_exact_zero(priv):
    s = torch.randn(1, 64)
    f = priv.filter(s, ConsentProfile.single_denied("age"))
    assert (f[:, 0:5] == 0.0).all()


def test_delete(priv):
    result = priv.delete("test_user")
    assert "deleted" in result
