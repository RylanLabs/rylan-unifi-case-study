"""Unit tests for guardrails behavior to improve coverage.

These tests exercise the decorator paths that wrap exceptions and verify the
FortressError semantics.
"""

import pytest

import app.guardrails as guardrails
from app.exceptions import FortressError


def test_guardrail_wraps_foreign_exception():
    @guardrails.guardrail(guardian="unit-test")
    def broken() -> None:
        raise ValueError("boom")

    with pytest.raises(FortressError) as excinfo:
        broken()

    # Ensure the original exception was wrapped and context includes guardian
    err = excinfo.value
    assert "[unit-test] ValueError: boom" in str(err)
    assert isinstance(err.context, dict)
    assert err.context.get("guardian") == "unit-test"
    assert err.context.get("function") == "broken"


def test_guardrail_preserves_fortress_error():
    @guardrails.guardrail(guardian="relay")
    def rethrow() -> None:
        raise FortressError("already", context={"guardian": "orig"})

    with pytest.raises(FortressError) as excinfo:
        rethrow()

    # Already-wrapped FortressError should be re-raised unchanged
    err = excinfo.value
    assert str(err) == "already"
    assert err.context.get("guardian") == "orig"
