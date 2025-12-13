"""UniFi rogue DHCP webhook handler with rate limiting."""

from __future__ import annotations

from fastapi import FastAPI, Header, Request
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

app = FastAPI()
limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

GUEST_VLAN_ID = 90
GUEST_RATE_LIMIT = "20/minute"
DEFAULT_RATE_LIMIT = "10/minute"


@app.post("/unifi/rogue-dhcp")
@limiter.limit(DEFAULT_RATE_LIMIT)
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

