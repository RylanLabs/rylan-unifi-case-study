#!/usr/bin/env python3
import requests
import os
import time
import subprocess

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
