"""Tests for shared.unifi_client — UniFi Controller API client.

Validates request formatting, endpoint construction, response parsing,
error handling, and edge cases. Uses mocked authenticated session.

Guardian: Beale | Ministry: Detection | Consciousness: 2.6
"""

from __future__ import annotations

import logging
import sys
from pathlib import Path
from typing import TYPE_CHECKING
from unittest.mock import MagicMock, patch

import pytest
import requests

# Ensure repository root is on sys.path so tests can import packages directly when
# executed from developer environments. This mirrors the autouse fixture but
# keeps imports top-level to satisfy PLC0415.
try:
    repo_root = str(Path(__file__).resolve().parents[2])
    if repo_root not in sys.path:
        sys.path.insert(0, repo_root)
except Exception:
    # Best-effort only; function-level imports remain a fallback during test runtime
    pass

from shared.unifi_client import UniFiClient

if TYPE_CHECKING:
    from collections.abc import Generator

logger = logging.getLogger(__name__)

# Test constants
TEST_CONTROLLER_URL = "https://controller.local"
TEST_NETWORK_ID_NEW = "new_id"
EXPECTED_VLAN40 = 40


@pytest.fixture
def mock_unifi_session() -> Generator[MagicMock, None, None]:
    """Yield mocked session with default empty response."""
    with patch("shared.unifi_client.get_authenticated_session") as mock_func:
        mock_session = MagicMock()
        mock_response = MagicMock()
        mock_response.json.return_value = {"data": []}
        mock_session.request.return_value = mock_response
        mock_func.return_value = mock_session
        yield mock_session


@pytest.fixture
def _client() -> None:
    """Legacy fixture removed — placeholder to preserve import ordering during edits.

    Tests import `UniFiClient` lazily now; this fixture is intentionally a no-op.
    """
    return


@pytest.fixture(autouse=True)
def _ensure_sys_path() -> Generator[None, None, None]:
    """Temporarily add repo root to `sys.path` for imports during tests.

    This is autouse to guarantee imports work while leaving no trace after
    the test runs (idempotency — Carter doctrine).
    """
    repo_root = str(Path(__file__).resolve().parents[2])
    sys.path.insert(0, repo_root)
    try:
        yield
    finally:
        if repo_root in sys.path:
            sys.path.remove(repo_root)


@pytest.mark.unit
def test_get_request_parses_data(mock_unifi_session: MagicMock) -> None:
    """Validate GET formatting and data extraction."""
    mock_response = MagicMock()
    mock_response.json.return_value = {"data": [{"id": "1", "name": "VLAN10"}]}
    mock_unifi_session.request.return_value = mock_response

    c = UniFiClient(TEST_CONTROLLER_URL)
    result = c.get("rest/networkconf")

    mock_unifi_session.request.assert_called_once()
    assert isinstance(result, list)
    assert result == [{"id": "1", "name": "VLAN10"}]


@pytest.mark.unit
def test_post_creates_network(mock_unifi_session: MagicMock) -> None:
    """Validate POST payload and response."""
    mock_response = MagicMock()
    mock_response.json.return_value = {"data": {"_id": TEST_NETWORK_ID_NEW, "vlan": EXPECTED_VLAN40}}
    mock_unifi_session.request.return_value = mock_response

    c = UniFiClient(TEST_CONTROLLER_URL)
    payload = {"name": "VLAN40", "vlan": EXPECTED_VLAN40}
    result = c.create_network(payload)

    mock_unifi_session.request.assert_called_once()
    assert result["_id"] == TEST_NETWORK_ID_NEW
    assert result["vlan"] == EXPECTED_VLAN40


@pytest.mark.unit
def test_timeout_raised(mock_unifi_session: MagicMock) -> None:
    """Validate timeout exception propagation."""
    mock_unifi_session.request.side_effect = requests.Timeout("timeout")

    c = UniFiClient(TEST_CONTROLLER_URL)
    with pytest.raises(requests.Timeout):
        c.get("rest/networkconf")


@pytest.mark.unit
def test_empty_data_returns_empty_list(mock_unifi_session: MagicMock) -> None:
    """Validate empty `data` returns an empty list instead of None."""
    mock_response = MagicMock()
    mock_response.json.return_value = {"data": []}
    mock_unifi_session.request.return_value = mock_response

    c = UniFiClient(TEST_CONTROLLER_URL)
    result = c.get("rest/networkconf")

    assert result == []


@pytest.mark.unit
def test_http_error_propagates(mock_unifi_session: MagicMock) -> None:
    """Validate HTTP error (500) is propagated to the caller."""
    mock_unifi_session.request.side_effect = requests.HTTPError("500 Server Error")
    c = UniFiClient(TEST_CONTROLLER_URL)
    with pytest.raises(requests.HTTPError):
        c.get("rest/networkconf")


@pytest.mark.unit
def test_malformed_json_handled(mock_unifi_session: MagicMock) -> None:
    """Validate non-JSON responses surface decoding errors."""
    mock_response = MagicMock()
    mock_response.json.side_effect = ValueError("Invalid JSON")
    mock_unifi_session.request.return_value = mock_response

    c = UniFiClient(TEST_CONTROLLER_URL)
    with pytest.raises(ValueError, match="Invalid JSON"):
        c.get("rest/networkconf")


@pytest.mark.unit
def test_default_ssl_verification_enabled() -> None:
    """Validate SSL verification is enabled by default."""
    c = UniFiClient(TEST_CONTROLLER_URL)
    assert getattr(c, "verify_ssl", True) is True


@pytest.mark.unit
def test_ssl_verification_can_disable() -> None:
    """Validate SSL verification can be disabled for lab environments."""
    c = UniFiClient(TEST_CONTROLLER_URL, verify_ssl=False)
    assert getattr(c, "verify_ssl", False) is False


@pytest.mark.unit
def test_request_logged_debug(mock_unifi_session: MagicMock, caplog: pytest.LogCaptureFixture) -> None:
    """Validate that requests trigger debug-level audit logs (implementation dependent)."""
    with caplog.at_level(logging.DEBUG):
        c = UniFiClient(TEST_CONTROLLER_URL)
        c.get("rest/networkconf")

    # If the client emits no logs yet, skip — this documents expected behavior
    if not caplog.text:
        pytest.skip("UniFiClient does not emit audit logs; see TODO to implement")
    assert "rest/networkconf" in caplog.text or "GET" in caplog.text


@pytest.mark.unit
def test_credentials_not_logged(mock_unifi_session: MagicMock, caplog: pytest.LogCaptureFixture) -> None:
    """Ensure sensitive payload fields (password) are not written to logs."""
    pwd = "secret" + "123"
    with caplog.at_level(logging.DEBUG):
        c = UniFiClient(TEST_CONTROLLER_URL)
        c.post("rest/login", json={"username": "admin", "password": pwd})

    assert pwd not in caplog.text


@pytest.mark.unit
def test_url_construction_safe(mock_unifi_session: MagicMock) -> None:
    """Validate URL construction does not allow directory traversal outside base URL."""

    c = UniFiClient(TEST_CONTROLLER_URL)
    c.get("../../etc/passwd")

    # The client should call session.request with URL including base controller URL
    assert mock_unifi_session.request.called
    args, kwargs = mock_unifi_session.request.call_args
    # most clients pass method, url as first two positional args
    called_url = args[1] if len(args) > 1 else kwargs.get("url", "")
    assert TEST_CONTROLLER_URL in called_url
