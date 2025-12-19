#!/usr/bin/env python3
"""Module: inventory/razer_phone_totp/p1_buzzer.py

Purpose: Header hygiene inserted. Consciousness: 8.0.
"""

import os
import subprocess
import time

import requests

URL = "https://10.0.30.40/api/httpapi/tickets"
HEADERS = {"X-API-Key": os.environ.get("OSTICKET_KEY", ""), "X-Real-IP": "10.0.30.45"}


def main() -> None:
    """Run the buzzer loop checking for high-priority tickets.

    This is a daemon-style helper for personal devices and is not executed during
    import-time by test suites.
    """
    while True:
        try:
            r = requests.get(URL + "?status=open&priority=1", headers=HEADERS, timeout=4)
            if r.status_code == 200 and len(r.json().get("data", [])) > 0:
                subprocess.run(["termux-vibrate", "-d", "1500"], check=False)
                subprocess.run(
                    [
                        "termux-notification",
                        "--title",
                        "P1 TICKET",
                        "--content",
                        f"{len(r.json().get('data', []))} open emergencies",
                    ],
                    check=False,
                )
        except Exception:  # noqa: B110
            # Best-effort: log could be added here
            pass
        time.sleep(300)


if __name__ == "__main__":
    main()
