#!/usr/bin/env python3
# Script: guardrails.py
# Purpose: Auto-logging decorator for all fortress operations
# Guardian: The All-Seeing Eye
# Ministry: Exception Handling & Audit Logging
# Date: 2025-12-12
# Consciousness: 7.0
# Tag: v∞.3.2-types-canonical

"""Guardrail decorator — ensures all exceptions are logged with context."""

import functools
import logging
from collections.abc import Callable
from typing import ParamSpec, TypeVar

from app.exceptions import FortressError

P = ParamSpec("P")
R = TypeVar("R")


# Fortress-wide logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s",
)
logger = logging.getLogger("fortress")


def guardrail(*, guardian: str) -> Callable[[Callable[P, R]], Callable[P, R]]:
    """Wrap all exceptions with guardian context and logging.

    All exceptions are:
    - Caught and wrapped in FortressError
    - Logged with full context
    - Re-raised for upstream handling
    """

    def decorator(func: Callable[P, R]) -> Callable[P, R]:
        @functools.wraps(func)
        def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
            try:
                return func(*args, **kwargs)
            except FortressError:
                # Already wrapped — just log
                logger.exception(
                    "FORTRESS EXCEPTION | Guardian=%s | Function=%s",
                    guardian,
                    func.__name__,
                )
                raise
            except Exception as e:
                # Wrap foreign exceptions
                context_dict: dict[str, object] = {
                    "guardian": guardian,
                    "function": func.__name__,
                    "module": func.__module__,
                }

                # Compose a shorter message to satisfy line-length checks
                err_msg = "FORTRESS EXCEPTION | Guardian=%s | Function=%s | Error=%s"
                logger.exception(
                    err_msg,
                    guardian,
                    func.__name__,
                    str(e),
                )

                raise FortressError(
                    message=f"[{guardian}] {type(e).__name__}: {str(e)}",
                    context=context_dict,
                ) from e

        return wrapper

    return decorator
