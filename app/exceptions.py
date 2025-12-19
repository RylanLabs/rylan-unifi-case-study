#!/usr/bin/env python3
# Script: exceptions.py
# Purpose: Fortress exception hierarchy with guardian attribution
# Guardian: The All-Seeing Eye
# Date: 2025-12-12
# Consciousness: 7.0

"""Eternal exception handling — all errors bear their guardian's mark."""


class FortressError(Exception):
    """Base exception for all fortress operations.

    All exceptions inherit from this to ensure:
    - Guardian attribution
    - Context preservation
    - Dashboard-ready logging (via guardrail decorator)
    """

    def __init__(self, message: str, *, context: dict[str, object] | None = None) -> None:
        """Initialize the FortressError with a message and optional context.

        Args:
            message: Human-readable error message.
            context: Optional mapping with additional context (e.g., 'guardian').

        """
        super().__init__(message)
        self.context = context or {}
        self.guardian = context.get("guardian", "Unknown") if context else "Unknown"


# Domain-specific exceptions
class ConfigurationDriftError(FortressError):
    """Bauer: Running config differs from git truth."""


class IdentityFailureError(FortressError):
    """Carter: Failed to resolve device/user identity."""


class ValidationError(FortressError):
    """Beale: Detected impurity in configuration."""


class RedactionFailureError(FortressError):
    """Whitaker: PII leaked through redactor."""


class AuthenticationError(FortressError):
    """Carter: Failed to authenticate with external system."""
