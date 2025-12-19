"""UniFi Controller API client.

Provides a small, typed wrapper around the UniFi controller HTTP API used by
`apply.py` and other automation. Follows RylanLab canonical standards: explicit
typing, clear docstrings, and robust network handling.

Guardian: Carter | Ministry: Identity | Consciousness: 9.5
"""

from __future__ import annotations

from typing import Any, TypeVar, cast

import requests

from shared.auth import get_authenticated_session

T = TypeVar("T", bound="UniFiClient")


class UniFiClient:
    """Minimal UniFi Controller API client.

    Args:
        base_url: Base URL of the UniFi controller (e.g. ``https://controller:8443``).
        verify_ssl: Whether to verify TLS certificates when making requests.
    """

    def __init__(self, base_url: str, verify_ssl: bool = True) -> None:
        self.base_url = base_url.rstrip("/")
        self.session = get_authenticated_session()
        self.verify_ssl = verify_ssl

    def _request(self, method: str, endpoint: str, **kwargs: Any) -> requests.Response:
        """Perform an HTTP request against the controller.

        This method centralizes URL building and default request options.
        """
        # Any: forwarded to requests.Session.request (dynamic kwargs accepted by requests)
        url = f"{self.base_url}/api/s/{endpoint.lstrip('/')}"
        kwargs.setdefault("verify", self.verify_ssl)
        response = self.session.request(method, url, **kwargs)
        response.raise_for_status()
        return response

    def get(self, endpoint: str, **kwargs: Any) -> list[dict[str, object]]:
        """HTTP GET, returning the parsed ``data`` element as a list.

        Returns an empty list when ``data`` is absent.
        """
        # Any: forwarded to requests.Session.request
        raw: Any = self._request("GET", endpoint, **kwargs).json()
        if not isinstance(raw, dict):
            # Defensive: unexpected JSON structure
            raise ValueError("Invalid JSON response: expected an object with 'data'")
        data = raw.get("data", [])
        if isinstance(data, list):
            return cast(list[dict[str, object]], data)
        return []

    def post(self, endpoint: str, **kwargs: Any) -> dict[str, object]:
        """HTTP POST, returning the parsed ``data`` element as a dict.

        Returns an empty dict when ``data`` is absent.
        """
        # Any: forwarded to requests.Session.request
        raw: Any = self._request("POST", endpoint, **kwargs).json()
        if not isinstance(raw, dict):
            raise ValueError("Invalid JSON response: expected an object with 'data'")
        data = raw.get("data", {})
        if isinstance(data, dict):
            return cast(dict[str, object], data)
        return {}

    def put(self, endpoint: str, **kwargs: Any) -> dict[str, object]:
        """HTTP PUT, returning the parsed ``data`` element as a dict.

        Returns an empty dict when ``data`` is absent.
        """
        # Any: forwarded to requests.Session.request
        raw: Any = self._request("PUT", endpoint, **kwargs).json()
        if not isinstance(raw, dict):
            raise ValueError("Invalid JSON response: expected an object with 'data'")
        data = raw.get("data", {})
        if isinstance(data, dict):
            return cast(dict[str, object], data)
        return {}

    # === Methods used by apply.py ===
    def list_networks(self) -> list[dict[str, object]]:
        """List network configurations from the controller."""
        return self.get("rest/networkconf")

    def create_network(self, payload: dict[str, object]) -> dict[str, object]:
        """Create a network using the provided payload."""
        return self.post("rest/networkconf", json=payload)

    def update_network(self, network_id: str, payload: dict[str, object]) -> dict[str, object]:
        """Update a network by id with `payload`."""
        return self.put(f"rest/networkconf/{network_id}", json=payload)

    def get_policy_table(self) -> list[dict[str, object]]:
        """Return the routing policy table from the controller."""
        return self.get("rest/routing/policytable")

    def update_policy_table(self, rules: list[dict[str, object]] | dict[str, object]) -> dict[str, object]:
        """Update the policy table. Accepts either the raw list of rules or

        a dict containing ``{"rules": [...]}`` as sent by other tooling.
        """
        rules_list: list[dict[str, object]]
        if isinstance(rules, dict) and "rules" in rules:
            candidate = rules["rules"]
            if not isinstance(candidate, list):
                raise ValueError("'rules' field must be a list")
            rules_list = candidate
        elif isinstance(rules, list):
            rules_list = rules
        else:
            raise ValueError("rules must be a list or a dict containing 'rules'")

        return self.put("rest/routing/policytable", json={"data": rules_list})

    @classmethod
    def from_env_or_inventory(cls: type[T]) -> T:
        """Factory obtaining controller URL from inventory or environment.

        Returns a configured `UniFiClient` instance. Keeps import local to avoid
        import-time side effects during test discovery.
        """

        from shared.auth import load_credentials

        creds = load_credentials()
        base_url = creds.get("unifi_base_url", "https://10.0.1.1:8443")
        return cls(base_url=base_url, verify_ssl=False)


__all__ = ["UniFiClient"]
