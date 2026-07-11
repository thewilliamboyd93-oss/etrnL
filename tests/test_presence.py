import pytest
from etrnl.presence import ProofOfPresence


@pytest.fixture
def p():
    return ProofOfPresence()


def test_issue(p):
    assert len(p.issue_challenge("s")["code"]) == 8


def test_unique(p):
    assert p.issue_challenge("a")["code"] != p.issue_challenge("b")["code"]


def test_verify_ok(p):
    c = p.issue_challenge("t")
    assert p.verify_response("t", c["code"], c["expression"], 2000)["passed"]


def test_wrong_code(p):
    p.issue_challenge("t")
    assert not p.verify_response("t", "wrong", "smile", 2000)["passed"]


def test_too_fast(p):
    c = p.issue_challenge("t")
    assert not p.verify_response("t", c["code"], c["expression"], 100)["passed"]
