#!/usr/bin/env python3
"""Adopt all pending UniFi devices using direct REST calls.

unifi-api-client compatible pattern.

Environment Variables:
  UNIFI_URL   -> e.g. https://10.0.1.20:8443
  UNIFI_USER  -> controller admin (no 2FA)
  UNIFI_PASS  -> password

Usage:
  python adopt-devices.py --site default --dry-run
  python adopt-devices.py --site default
"""

from __future__ import annotations

import argparse
import logging
import os
import sys
import time

import requests
import urllib3  # type: ignore[import-untyped]

urllib3.disable_warnings()  # self-signed certs

SESSION = requests.Session()

logging.basicConfig(level=logging.INFO, format="%(levelname)s | %(message)s")
logger = logging.getLogger("adopt")

HTTP_OK = 200
DEVICE_STATE_ADOPTED = 1


def fail(msg: str) -> None:
    """Log error and exit."""
    logger.error(msg)
    sys.exit(1)


def login(url: str, username: str, password: str) -> None:
    """Authenticate with UniFi controller."""
    resp = SESSION.post(
        f"{url}/api/login",
        json={"username": username, "password": password},
        verify=False,
    )
    if resp.status_code != HTTP_OK:
        fail(f"Login failed ({resp.status_code})")
    logger.info("Authenticated")


def list_devices(url: str, site: str) -> list[dict]:
    """Retrieve all devices from controller."""
    endpoint = f"{url}/proxy/network/api/s/{site}/stat/device"
    resp = SESSION.get(endpoint, verify=False)
    if resp.status_code != HTTP_OK:
        fail(f"Device list failed ({resp.status_code})")
    return resp.json().get("data", [])


def adopt(url: str, site: str, mac: str) -> None:
    """Send adopt command for device MAC."""
    payload = {"cmd": "adopt", "mac": mac}
    resp = SESSION.post(
        f"{url}/proxy/network/api/s/{site}/cmd/devmgr",
        json=payload,
        verify=False,
    )
    if resp.status_code == HTTP_OK:
        logger.info("Adopt command sent for %s", mac)
    else:
        logger.error("Failed to adopt %s: %s %s", mac, resp.status_code, resp.text)


def main() -> None:
    """Execute device adoption workflow."""
    parser = argparse.ArgumentParser(description="Adopt all pending UniFi devices")
    parser.add_argument("--site", default="default", help="UniFi site name")
    parser.add_argument("--dry-run", action="store_true", help="List only")
    args = parser.parse_args()

    url = os.getenv("UNIFI_URL")
    user = os.getenv("UNIFI_USER")
    password = os.getenv("UNIFI_PASS")

    if not url or not user or not password:
        fail("UNIFI_USER/UNIFI_PASS must be set in environment")

    logger.info("Controller: %s (site=%s)", url, args.site)
    login(url, user, password)

    devices = list_devices(url, args.site)
    if not devices:
        logger.info("No devices discovered.")
        return

    pending = [d for d in devices if d.get("state") != DEVICE_STATE_ADOPTED]
    logger.info("Found %d devices; %d pending adoption", len(devices), len(pending))

    for d in devices:
        status = "ADOPTED" if d.get("state") == DEVICE_STATE_ADOPTED else "PENDING"
        logger.info(
            "  %s %s %s %s %s",
            status.ljust(7),
            d.get("model", "?").ljust(12),
            d.get("mac"),
            d.get("ip", "-"),
            d.get("name", "(unnamed)"),
        )

    if args.dry_run:
        logger.info("Dry-run complete; no adoption performed.")
        return

    for d in pending:
        mac = d.get("mac")
        if mac:
            adopt(url, args.site, mac)
        time.sleep(2)

    logger.info("Pass complete. Re-run with --dry-run to verify final state.")


if __name__ == "__main__":
    main()
