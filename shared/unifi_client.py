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

    # Policy table endpoints (community-documented)
    def get_policy_table(self) -> Dict[str, Any]:
        r = self.session.get(self._url('rest/routingpolicy'), verify=False)
        r.raise_for_status()
        data = r.json().get('data', [])
        return data[0] if data else {"rules": []}

    def update_policy_table(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        # Some controllers require PUT to existing policy id; fall back to POST when none
        current = self.get_policy_table()
        policy_id = current.get('_id')
        if policy_id:
            r = self.session.put(self._url(f"rest/routingpolicy/{policy_id}"), json=payload, verify=False)
        else:
            r = self.session.post(self._url('rest/routingpolicy'), json=payload, verify=False)
        r.raise_for_status()
        return r.json()

    # Traffic management / QoS endpoints (community-documented)
    def get_traffic_mgmt(self) -> Dict[str, Any]:
        r = self.session.get(self._url('rest/trafficmgmt'), verify=False)
        r.raise_for_status()
        data = r.json().get('data', [])
        return data[0] if data else {}

    def update_traffic_mgmt(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        current = self.get_traffic_mgmt()
        tm_id = current.get('_id')
        if tm_id:
            r = self.session.put(self._url(f"rest/trafficmgmt/{tm_id}"), json=payload, verify=False)
        else:
            r = self.session.post(self._url('rest/trafficmgmt'), json=payload, verify=False)
        r.raise_for_status()
        return r.json()


__all__ = ["UniFiClient"]
