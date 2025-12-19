"""Unit tests for guardrails behavior to improve coverage.

These tests exercise the decorator paths that wrap exceptions and verify the
FortressError semantics.
"""

import pytest

import app.guardrails as guardrails
from app.exceptions import FortressError


def test_guardrail_wraps_foreign_exception() -> None:
    """Verify guardrail wraps non-FortressError exceptions and preserves context."""

    @guardrails.guardrail(guardian="unit-test")
    def broken() -> None:
        msg = "boom"
        raise ValueError(msg)

    with pytest.raises(FortressError) as excinfo:
        broken()

    # Ensure the original exception was wrapped and context includes guardian
    err = excinfo.value
    assert "[unit-test] ValueError: boom" in str(err)
    assert isinstance(err.context, dict)
    assert err.context.get("guardian") == "unit-test"
    assert err.context.get("function") == "broken"


def test_guardrail_preserves_fortress_error() -> None:
    """Verify that an already-wrapped FortressError is re-raised unchanged."""

    @guardrails.guardrail(guardian="relay")
    def rethrow() -> None:
        msg = "already"
        raise FortressError(msg, context={"guardian": "orig"})

    with pytest.raises(FortressError) as excinfo:
        rethrow()

    # Already-wrapped FortressError should be re-raised unchanged
    err = excinfo.value
    assert str(err) == "already"
    assert err.context.get("guardian") == "orig"
