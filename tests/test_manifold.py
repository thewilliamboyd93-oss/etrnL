"""Tests for IdentityManifold."""

import torch
import pytest
from etrnl.manifold import IdentityManifold


@pytest.fixture
def manifold():
    return IdentityManifold()


def test_encode_voice(manifold):
    point = manifold.encode(voice=torch.randn(4, 32))
    assert point.shape == (4, 128)


def test_encode_all_missing(manifold):
    point = manifold.encode()
    assert point.shape == (1, 128)


def test_generate_face(manifold):
    point = manifold.encode(voice=torch.randn(2, 32))
    face = manifold.generate(point)
    assert face.shape == (2, 3, 256, 256)


def test_navigate(manifold):
    point = manifold.encode(voice=torch.randn(1, 32))
    new_point = manifold.navigate(point, "nostalgia", 0.5)
    assert new_point.shape == (1, 128)
    assert not torch.equal(point, new_point)


def test_interpolate(manifold):
    a = manifold.encode(voice=torch.randn(1, 32))
    b = manifold.encode(voice=torch.randn(1, 32))
    mid = manifold.interpolate(a, b, 0.5)
    assert mid.shape == (1, 128)
