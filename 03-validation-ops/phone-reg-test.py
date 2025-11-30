"""Basic VoIP registration probe (placeholder).

Intended to query a SIP endpoint or PBX REST API to confirm phones are
registered. Adjust implementation to real FreePBX / Asterisk interface.
"""
from __future__ import annotations

import os
import sys
import requests

PBX_API = os.getenv("PBX_API", "http://10.0.20.50:8080/api/peers")


def main():
    try:
        r = requests.get(PBX_API, timeout=5)
        r.raise_for_status()
        data = r.json()
    except Exception as e:
        print(f"❌ Failed to query PBX peers: {e}")
        sys.exit(1)

    # Expect a list of peers with status field
    unhealthy = [p for p in data if p.get("status") != "OK"]
    if unhealthy:
        print("❌ Unhealthy SIP peers detected:")
        for p in unhealthy:
            print(f"  - {p.get('name')} status={p.get('status')}")
        sys.exit(2)
    print(f"✅ {len(data)} SIP peers healthy")


if __name__ == "__main__":
    main()
