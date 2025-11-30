"""UniFi controller authentication utilities.

Provides a thin wrapper around requests.Session for logging into the UniFi
Network Application. Session cookies are retained for subsequent calls.

Environment precedence:
  UNIFI_URL, UNIFI_USER, UNIFI_PASS (preferred)
Fallback:
  inventory.yaml under shared/ (unifi_controller section)
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Optional, Dict, Any
import requests
import yaml

requests.packages.urllib3.disable_warnings()  # controller often self-signed


class UniFiAuth:
    def __init__(self, url: str, username: str, password: str, verify_ssl: bool = False):
        self.url = url.rstrip('/')
        self.username = username
        self.password = password
        self.session = requests.Session()
        self.session.verify = verify_ssl

    def login(self) -> None:
        resp = self.session.post(f"{self.url}/api/login", json={
            "username": self.username,
            "password": self.password,
            "remember": True
        }, timeout=15, verify=False)
        if resp.status_code != 200:
            raise RuntimeError(f"Login failed: {resp.status_code} {resp.text[:120]}")


def load_credentials() -> Dict[str, Any]:
    """Load credentials from env or inventory.yaml"""
    inv_path = Path(__file__).parent / "inventory.yaml"
    creds: Dict[str, Any] = {}
    if inv_path.exists():
        with inv_path.open('r', encoding='utf-8') as f:
            data = yaml.safe_load(f) or {}
            creds = data.get('unifi_controller', {})
    # Override with env if set
    url = os.getenv('UNIFI_URL', creds.get('url', 'https://10.0.1.20:8443'))
    user = os.getenv('UNIFI_USER', creds.get('username'))
    password = os.getenv('UNIFI_PASS', creds.get('password'))
    return {"url": url, "username": user, "password": password}


def get_authenticated_session() -> requests.Session:
    c = load_credentials()
    if not c.get('username') or not c.get('password'):
        raise RuntimeError("Missing UniFi credentials (env or inventory.yaml)")
    auth = UniFiAuth(c['url'], c['username'], c['password'])
    auth.login()
    return auth.session


__all__ = ["UniFiAuth", "load_credentials", "get_authenticated_session"]
