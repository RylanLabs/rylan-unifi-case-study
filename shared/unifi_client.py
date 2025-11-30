"""Higher-level UniFi client utilities using authenticated session.

Provides simple wrappers for common controller queries used by declarative
apply operations (networks/VLANs). Additional endpoints can be appended
incrementally as needed.
"""

from __future__ import annotations

from typing import List, Dict, Any
import requests

from .auth import get_authenticated_session, load_credentials


class UniFiClient:
    def __init__(self, site: str = "default"):
        creds = load_credentials()
        self.base_url = creds['url'].rstrip('/')
        self.session = get_authenticated_session()
        self.site = site

    def _url(self, path: str) -> str:
        return f"{self.base_url}/proxy/network/api/s/{self.site}/{path.lstrip('/')}"

    def list_networks(self) -> List[Dict[str, Any]]:
        r = self.session.get(self._url('rest/networkconf'), verify=False)
        r.raise_for_status()
        return r.json().get('data', [])

    def create_network(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        r = self.session.post(self._url('rest/networkconf'), json=payload, verify=False)
        r.raise_for_status()
        return r.json()

    def update_network(self, network_id: str, payload: Dict[str, Any]) -> Dict[str, Any]:
        r = self.session.put(self._url(f"rest/networkconf/{network_id}"), json=payload, verify=False)
        r.raise_for_status()
        return r.json()


__all__ = ["UniFiClient"]
