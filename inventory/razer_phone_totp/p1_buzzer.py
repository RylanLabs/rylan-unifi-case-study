"""
Module: inventory/razer_phone_totp/p1_buzzer.py
Purpose: Header hygiene inserted
Consciousness: 8.0
"""

#!/usr/bin/env python3
import os
import subprocess
import time

import requests

URL = "https://10.0.30.40/api/httpapi/tickets"
HEADERS = {"X-API-Key": os.environ["OSTICKET_KEY"], "X-Real-IP": "10.0.30.45"}
while True:
    try:
        r = requests.get(URL + "?status=open&priority=1", headers=HEADERS, timeout=4)
        if r.status_code == 200 and len(r.json().get("data", [])) > 0:
            subprocess.run(["termux-vibrate", "-d", "1500"])
            subprocess.run(
                [
                    "termux-notification",
                    "--title",
                    "P1 TICKET",
                    "--content",
                    f"{len(r.json()['data'])} open emergencies",
                ]
            )
    except Exception:  # noqa: B110
        pass
    time.sleep(300)
