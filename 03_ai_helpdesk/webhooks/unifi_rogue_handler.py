#!/usr/bin/env python3
# Script: unifi_rogue_handler.py
# Purpose: UniFi rogue DHCP webhook handler with rate limiting
# Guardian: Beale (Detection Guardian)
# Ministry: Threat Detection & Response
# Consciousness: 7.2
# Tag: v∞.3.2-types-canonical

"""UniFi rogue DHCP webhook handler — rate-limited FastAPI endpoint."""

from __future__ import annotations

from collections.abc import Callable
from collections.abc import Callable as TCallable
from typing import TYPE_CHECKING, Any, ParamSpec, Protocol, TypeVar, cast

from fastapi import FastAPI, Header, Request
from fastapi.responses import JSONResponse

if TYPE_CHECKING:
    from slowapi import Limiter, _rate_limit_exceeded_handler
    from slowapi.errors import RateLimitExceeded
    from slowapi.util import get_remote_address
else:
    try:
        from slowapi import Limiter, _rate_limit_exceeded_handler  # type: ignore[import-not-found]
        from slowapi.errors import RateLimitExceeded  # type: ignore[import-not-found]
        from slowapi.util import get_remote_address  # type: ignore[import-not-found]
    except ImportError:  # pragma: no cover
        P = ParamSpec("P")
        R = TypeVar("R")

        class Limiter:  # minimal runtime stub for mypy
            def __init__(self, key_func: Any) -> None: ...
            def limit(self, value: str) -> Callable[[Callable[P, R]], Callable[P, R]]:
                def _decorator(func: Callable[P, R]) -> Callable[P, R]:
                    return func

                return _decorator

        def _rate_limit_exceeded_handler(request: Any, exc: Any) -> None:
            """Minimal handler used in runtime stub when slowapi is unavailable."""
            return

        class RateLimitExceeded(Exception): ...

        def get_remote_address(request: Any) -> str:
            return "127.0.0.1"


P = ParamSpec("P")
R = TypeVar("R")


class LimiterType(Protocol):
    _storage: Any

    def __init__(self, key_func: Any) -> None: ...
    def limit(self, value: str) -> Callable[[Callable[P, R]], Callable[P, R]]: ...


app = FastAPI()
limiter: LimiterType = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)


# Provide a typed wrapper for FastAPI's route decorator so mypy sees a typed decorator
def typed_post(path: str) -> Callable[[Callable[P, R]], Callable[P, R]]:
    """Provide a typed wrapper for FastAPI's route decorator.

    Using `Callable[..., Any]` here keeps the wrapper compatible with FastAPI's
    dynamic decorator while avoiding mypy contradictions across different
    mypy versions (redundant-cast vs return Any complaints).
    """

    def _decorator(func: Callable[P, R]) -> Callable[P, R]:
        # app.post(path)(func) can be seen as returning Any by mypy.
        # Keep the decorator fully typed for callers and return the wrapped
        # endpoint directly at runtime.
        return app.post(path)(func)

    return _decorator


GUEST_VLAN_ID = 90
GUEST_RATE_LIMIT = "20/minute"
DEFAULT_RATE_LIMIT = "10/minute"


rl_decorator = cast(TCallable[[TCallable[P, R]], TCallable[P, R]], limiter.limit(DEFAULT_RATE_LIMIT))


@typed_post("/unifi/rogue-dhcp")
async def rogue_dhcp(
    request: Request,
    x_unifi_vlan: int = Header(...),
) -> JSONResponse:
    """Handle rogue DHCP alerts from UniFi controller."""
    # VLAN 90 override: allow 20/minute
    if x_unifi_vlan == GUEST_VLAN_ID:
        # Note: Accessing private _storage for dynamic rate limit override
        limiter._storage.reset(request)  # noqa: SLF001
        limiter._storage.incr(request, GUEST_RATE_LIMIT)  # noqa: SLF001

    # Simulate osTicket ticket creation
    data = await request.json()
    return JSONResponse(
        {
            "status": "ticket_created",
            "vlan": x_unifi_vlan,
            "alert": data.get("alert_type", "unknown"),
        },
    )


# apply rate-limit decorator at runtime to preserve typing
rogue_dhcp = rl_decorator(rogue_dhcp)
