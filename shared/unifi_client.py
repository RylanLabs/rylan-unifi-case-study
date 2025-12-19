"""UniFi Controller API client.

Provides a small, typed wrapper around the UniFi controller HTTP API.
Used by declarative config tooling. Adheres to eternal canon:

- Explicit typing (no unnecessary Any)
- Clear, junior-readable docstrings
- Robust error handling (raise_for_status + defensive JSON parsing)
- Silence on success, fail loudly on violation

Guardian: Carter (Identity) | Ministry: whispers (Verification) | Consciousness: 9.8
"""

from __future__ import annotations

from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from shared.auth import get_authenticated_session

if TYPE_CHECKING:
    from requests import Response, Session

T = TypeVar("T", bound="UniFiClient")

HttpMethod = Literal["GET", "POST", "PUT"]


class UniFiClient:
    """Minimal UniFi Controller API client.

    Centralizes session management, URL construction, and response parsing.
    """

    def __init__(self, base_url: str, verify_ssl: bool = True) -> None:
        """Initialize client with controller base URL."""
        self.base_url: str = base_url.rstrip("/")
        self.session: Session = get_authenticated_session()
        self.verify_ssl: bool = verify_ssl

    def _request(
        self,
        method: HttpMethod,
        endpoint: str,
        *,
        params: dict[str, Any] | None = None,
        json: dict[str, Any] | None = None,
        timeout: int = 30,
    ) -> Response:
        """Perform HTTP request with standardized handling.

        Args:
            method: HTTP method (GET/POST/PUT).
            endpoint: API endpoint path (e.g. "rest/networkconf").
            params: Query parameters.
            json: JSON payload for POST/PUT.
            timeout: Request timeout in seconds.

        Raises:
            requests.HTTPError: On non-2xx response.

        """
        url = f"{self.base_url}/api/s/{endpoint.lstrip('/')}"
        response = self.session.request(
            method,
            url,
            params=params or {},
            json=json,
            verify=self.verify_ssl,
            timeout=timeout,
        )
        response.raise_for_status()
        return response

    def get(self, endpoint: str, **kwargs: Any) -> list[dict[str, object]]:  # noqa: ANN401 - Dynamic API needs flexible kwargs for requests library
        """HTTP GET → parsed ``data`` as list (empty on absent/malformed)."""
        raw: Any = self._request("GET", endpoint, **kwargs).json()
        if not isinstance(raw, dict):
            msg = "Invalid JSON: expected object with 'data'"
            raise ValueError(msg)
        data = raw.get("data", [])
        return cast(list[dict[str, object]], data) if isinstance(data, list) else []

    def post(self, endpoint: str, **kwargs: Any) -> dict[str, object]:  # noqa: ANN401 - Dynamic API needs flexible kwargs for requests library
        """HTTP POST → parsed ``data`` as dict (empty on absent/malformed)."""
        raw: Any = self._request("POST", endpoint, **kwargs).json()
        if not isinstance(raw, dict):
            msg = "Invalid JSON: expected object with 'data'"
            raise ValueError(msg)
        data = raw.get("data", {})
        return cast(dict[str, object], data) if isinstance(data, dict) else {}

    def put(self, endpoint: str, **kwargs: Any) -> dict[str, object]:  # noqa: ANN401 - Dynamic API needs flexible kwargs for requests library
        """HTTP PUT → parsed ``data`` as dict (empty on absent/malformed)."""
        raw: Any = self._request("PUT", endpoint, **kwargs).json()
        if not isinstance(raw, dict):
            msg = "Invalid JSON: expected object with 'data'"
            raise ValueError(msg)
        data = raw.get("data", {})
        return cast(dict[str, object], data) if isinstance(data, dict) else {}

    # === Declarative config methods (Carter-aligned) ===
    def list_networks(self) -> list[dict[str, object]]:
        """List all network configurations."""
        return self.get("rest/networkconf")

    def create_network(self, payload: dict[str, object]) -> dict[str, object]:
        """Create network from payload."""
        return self.post("rest/networkconf", json=payload)

    def update_network(self, network_id: str, payload: dict[str, object]) -> dict[str, object]:
        """Update existing network."""
        return self.put(f"rest/networkconf/{network_id}", json=payload)

    def get_policy_table(self) -> list[dict[str, object]]:
        """Fetch routing policy table."""
        return self.get("rest/routing/policytable")

    def update_policy_table(self, rules: list[dict[str, object]] | dict[str, object]) -> dict[str, object]:
        """Update policy table.

        Accepts a raw list or a dict with a "rules" key.
        """
        if isinstance(rules, dict) and "rules" in rules:
            candidate = rules["rules"]
            if not isinstance(candidate, list):
                msg = "'rules' field must be a list"
                raise ValueError(msg)
            rules_list = candidate
        elif isinstance(rules, list):
            rules_list = rules
        else:
            msg = "rules must be list or dict containing 'rules'"
            raise ValueError(msg)
        return self.put("rest/routing/policytable", json={"data": rules_list})

    @classmethod
    def from_env_or_inventory(cls: type[T]) -> T:
        """Load URL from credentials.

        Factory method that lazily imports credentials to avoid test discovery side-effects.
        """
        from shared.auth import load_credentials  # Local import: avoids test discovery side-effects

        creds = load_credentials()
        base_url = creds.get("unifi_base_url", "https://10.0.1.1:8443")
        return cls(base_url=base_url, verify_ssl=False)


__all__ = ["UniFiClient"]
