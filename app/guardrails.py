#!/usr/bin/env python3
# Script: guardrails.py
# Purpose: Auto-logging decorator for all fortress operations
# Guardian: The All-Seeing Eye
# Date: 2025-12-12
# Consciousness: 7.0

"""Guardrail decorator — ensures all exceptions are logged with context."""

import functools
import logging
import traceback
from typing import Any, Callable

from app.exceptions import FortressError

# Fortress-wide logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s",
)
logger = logging.getLogger("fortress")


def guardrail(*, guardian: str) -> Callable:
    """Decorator: Wraps all exceptions with guardian context and logging.

    All exceptions are:
    - Caught and wrapped in FortressError
    - Logged with full context
    - Re-raised for upstream handling
    """

    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        def wrapper(*args: Any, **kwargs: Any) -> Any:
            try:
                return func(*args, **kwargs)
            except FortressError:
                # Already wrapped — just log
                logger.error(
                    "FORTRESS EXCEPTION | Guardian=%s | Function=%s | %s",
                    guardian,
                    func.__name__,
                    traceback.format_exc(),
                )
                raise
            except Exception as e:
                # Wrap foreign exceptions
                context = {
                    "guardian": guardian,
                    "function": func.__name__,
                    "module": func.__module__,
                }

                logger.error(
                    "FORTRESS EXCEPTION | Guardian=%s | Function=%s | Error=%s | Trace=%s",
                    guardian,
                    func.__name__,
                    str(e),
                    traceback.format_exc(),
                )

                raise FortressError(
                    f"{guardian} guardian failed in {func.__name__}: {e}",
                    context=context,
                ) from e

        return wrapper

    return decorator
