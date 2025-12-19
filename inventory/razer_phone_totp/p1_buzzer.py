#!/usr/bin/env python3
"""Module: inventory/razer_phone_totp/p1_buzzer.py

Purpose: Header hygiene inserted. Consciousness: 8.0.
"""

import logging
import os
import shutil
import subprocess
import time

import requests

logger = logging.getLogger(__name__)

TERMUX_VIBRATE = shutil.which("termux-vibrate") or "/data/data/com.termux/files/usr/bin/termux-vibrate"
TERMUX_NOTIFY = shutil.which("termux-notification") or "/data/data/com.termux/files/usr/bin/termux-notification"


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
                # Safe invocation: prefer explicit binary paths validated at startup
                if TERMUX_VIBRATE:
                    try:
                        subprocess.run([TERMUX_VIBRATE, "-d", "1500"], check=True)
                    except subprocess.CalledProcessError:
                        logger.exception("termux-vibrate failed")
                else:
                    logger.debug("termux-vibrate not found; skipping vibration")

                if TERMUX_NOTIFY:
                    try:
                        subprocess.run(
                            [
                                TERMUX_NOTIFY,
                                "--title",
                                "P1 TICKET",
                                "--content",
                                f"{len(r.json().get('data', []))} open emergencies",
                            ],
                            check=True,
                        )
                    except subprocess.CalledProcessError:
                        logger.exception("termux-notification failed")
                else:
                    logger.debug("termux-notification not found; skipping notification")
        except (requests.RequestException, subprocess.CalledProcessError) as e:
            logger.exception("p1_buzzer main loop error: %s", e)
        time.sleep(300)


if __name__ == "__main__":
    main()
