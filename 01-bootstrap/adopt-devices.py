#!/usr/bin/env python3
"""Adopt all pending UniFi devices using direct REST calls (unifi-api-client compatible pattern).

Environment Variables:
  UNIFI_URL   -> e.g. https://10.0.1.20:8443
  UNIFI_USER  -> controller admin (no 2FA)
  UNIFI_PASS  -> password

Usage:
  python adopt-devices.py --site default --dry-run
  python adopt-devices.py --site default
"""

import argparse
import os
import sys
import time
from typing import List
import requests

import urllib3  # type: ignore

urllib3.disable_warnings()  # self-signed certs

SESSION = requests.Session()


def fail(msg: str):
    print(f"❌ {msg}")
    sys.exit(1)


def login(url: str, username: str, password: str):
    resp = SESSION.post(
        f"{url}/api/login",
        json={"username": username, "password": password},
        verify=False,
    )
    if resp.status_code != 200:
        fail(f"Login failed ({resp.status_code})")
    print("✅ Authenticated")


def list_devices(url: str, site: str) -> List[dict]:
    endpoint = f"{url}/proxy/network/api/s/{site}/stat/device"
    resp = SESSION.get(endpoint, verify=False)
    if resp.status_code != 200:
        fail(f"Device list failed ({resp.status_code})")
    return resp.json().get("data", [])


def adopt(url: str, site: str, mac: str):
    payload = {"cmd": "adopt", "mac": mac}
    resp = SESSION.post(
        f"{url}/proxy/network/api/s/{site}/cmd/devmgr", json=payload, verify=False
    )
    if resp.status_code == 200:
        print(f"  🚀 Adopt command sent for {mac}")
    else:
        print(f"  ❌ Failed to adopt {mac}: {resp.status_code} {resp.text}")


def main():
    parser = argparse.ArgumentParser(description="Adopt all pending UniFi devices")
    parser.add_argument("--site", default="default", help="UniFi site name")
    parser.add_argument("--dry-run", action="store_true", help="List devices only")
    args = parser.parse_args()

    url = os.getenv("UNIFI_URL", "https://10.0.1.20:8443")
    user = os.getenv("UNIFI_USER")
    password = os.getenv("UNIFI_PASS")
    if not user or not password:
        fail("UNIFI_USER/UNIFI_PASS must be set in environment")

    print(f"🔌 Controller: {url} (site={args.site})")
    login(url, user, password)

    devices = list_devices(url, args.site)
    if not devices:
        print("No devices discovered.")
        return

    pending = [d for d in devices if d.get("state") != 1]
    print(f"Found {len(devices)} devices; {len(pending)} pending adoption")
    for d in devices:
        status = "ADOPTED" if d.get("state") == 1 else "PENDING"
        print(
            f"  {status:7} {d.get('model','?'):12} {d.get('mac')} {d.get('ip','-')} {d.get('name','(unnamed)')}"
        )

    if args.dry_run:
        print("Dry-run complete; no adoption performed.")
        return

    for dev in pending:
        adopt(url, args.site, dev.get("mac"))
        time.sleep(2)

    print("Pass complete. Re-run with --dry-run to verify final state.")


if __name__ == "__main__":
    main()
