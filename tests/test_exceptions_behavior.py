"""Unit tests for FortressError behaviors to improve coverage."""

from app.exceptions import FortressError


def test_fortress_error_guardian_from_context() -> None:
    err = FortressError("msg", context={"guardian": "sage"})
    assert err.guardian == "sage"
    assert isinstance(err.context, dict)


def test_fortress_error_guardian_default_unknown() -> None:
    err = FortressError("msg")
    assert err.guardian == "Unknown"
    assert err.context == {}
