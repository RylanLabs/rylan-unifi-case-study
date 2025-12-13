"""Tests for shared/unifi_client.py – UniFi Controller API client.

Validates HTTP request formatting, endpoint handling, and response parsing.
"""

import pytest
from unittest.mock import MagicMock, patch
import requests
from shared.unifi_client import UniFiClient


class TestUniFiClientInit:
    """Test UniFiClient instantiation."""

    def test_client_init_basic(self):
        """Initialize UniFiClient with URL and defaults."""
        client = UniFiClient("https://controller.local")
        assert client.base_url == "https://controller.local"
        assert client.verify_ssl is True
        assert client.session is not None

    def test_client_init_trailing_slash_removed(self):
        """Client strips trailing slashes from base_url."""
        client = UniFiClient("https://controller.local/")
        assert client.base_url == "https://controller.local"

    def test_client_init_ssl_verification_disabled(self):
        """Client respects verify_ssl=False."""
        client = UniFiClient("https://controller.local", verify_ssl=False)
        assert client.verify_ssl is False


class TestUniFiClientRequests:
    """Test HTTP request methods."""

    @patch("shared.unifi_client.get_authenticated_session")
    def test_get_request(self, mock_session_func):
        """Test GET request formatting."""
        mock_response = MagicMock()
        mock_response.json.return_value = {"data": [{"id": "1", "name": "VLAN10"}]}
        mock_session = MagicMock()
        mock_session.request.return_value = mock_response
        mock_session_func.return_value = mock_session

        client = UniFiClient("https://controller.local")
        result = client.get("rest/networkconf")

        mock_session.request.assert_called_once()
        call_args = mock_session.request.call_args
        assert call_args[0][0] == "GET"
        assert "rest/networkconf" in call_args[0][1]
        assert result == [{"id": "1", "name": "VLAN10"}]

    @patch("shared.unifi_client.get_authenticated_session")
    def test_post_request(self, mock_session_func):
        """Test POST request with JSON payload."""
        mock_response = MagicMock()
        mock_response.json.return_value = {"data": {"id": "new_id"}}
        mock_session = MagicMock()
        mock_session.request.return_value = mock_response
        mock_session_func.return_value = mock_session

        client = UniFiClient("https://controller.local")
        payload = {"name": "VLAN20", "vlan": 20}
        result = client.post("rest/networkconf", json=payload)

        mock_session.request.assert_called_once()
        call_args = mock_session.request.call_args
        assert call_args[0][0] == "POST"
        assert call_args[1]["json"] == payload
        assert result == {"id": "new_id"}

    @patch("shared.unifi_client.get_authenticated_session")
    def test_put_request(self, mock_session_func):
        """Test PUT request for updates."""
        mock_response = MagicMock()
        mock_response.json.return_value = {
            "data": {"id": "existing_id", "updated": True}
        }
        mock_session = MagicMock()
        mock_session.request.return_value = mock_response
        mock_session_func.return_value = mock_session

        client = UniFiClient("https://controller.local")
        payload = {"id": "existing_id", "name": "VLAN20_updated"}
        result = client.put("rest/networkconf/id", json=payload)

        mock_session.request.assert_called_once()
        call_args = mock_session.request.call_args
        assert call_args[0][0] == "PUT"
        assert result == {"id": "existing_id", "updated": True}


class TestUniFiClientNetworkMethods:
    """Test network-specific API methods."""

    @patch("shared.unifi_client.get_authenticated_session")
    def test_list_networks(self, mock_session_func):
        """list_networks() returns network list."""
        mock_response = MagicMock()
        mock_response.json.return_value = {
            "data": [
                {"_id": "1", "name": "VLAN10", "vlan": 10},
                {"_id": "2", "name": "VLAN30", "vlan": 30},
            ]
        }
        mock_session = MagicMock()
        mock_session.request.return_value = mock_response
        mock_session_func.return_value = mock_session

        client = UniFiClient("https://controller.local")
        networks = client.list_networks()

        assert len(networks) == 2
        assert networks[0]["name"] == "VLAN10"
        assert networks[1]["vlan"] == 30

    @patch("shared.unifi_client.get_authenticated_session")
    def test_create_network(self, mock_session_func):
        """create_network() creates and returns network."""
        mock_response = MagicMock()
        mock_response.json.return_value = {
            "data": {"_id": "new_id", "name": "VLAN40", "vlan": 40}
        }
        mock_session = MagicMock()
        mock_session.request.return_value = mock_response
        mock_session_func.return_value = mock_session

        client = UniFiClient("https://controller.local")
        payload = {"name": "VLAN40", "vlan": 40}
        result = client.create_network(payload)

        assert result["_id"] == "new_id"
        assert result["name"] == "VLAN40"


class TestUniFiClientErrorHandling:
    """Test error handling and edge cases."""

    @patch("shared.unifi_client.get_authenticated_session")
    def test_request_http_error(self, mock_session_func):
        """HTTP errors are raised."""
        mock_response = MagicMock()
        mock_response.raise_for_status.side_effect = requests.HTTPError(
            "401 Unauthorized"
        )
        mock_session = MagicMock()
        mock_session.request.return_value = mock_response
        mock_session_func.return_value = mock_session

        client = UniFiClient("https://controller.local")
        with pytest.raises(requests.HTTPError):
            client.get("rest/networkconf")

    @patch("shared.unifi_client.get_authenticated_session")
    def test_request_empty_data_response(self, mock_session_func):
        """Response with no 'data' key returns empty list/dict."""
        mock_response = MagicMock()
        mock_response.json.return_value = {}  # No 'data' key
        mock_session = MagicMock()
        mock_session.request.return_value = mock_response
        mock_session_func.return_value = mock_session

        client = UniFiClient("https://controller.local")
        result = client.get("rest/networkconf")

        # Should return empty list for GET
        assert result == []

    @patch("shared.unifi_client.get_authenticated_session")
    def test_endpoint_url_construction(self, mock_session_func):
        """Endpoint URLs are correctly constructed."""
        mock_response = MagicMock()
        mock_response.json.return_value = {"data": []}
        mock_session = MagicMock()
        mock_session.request.return_value = mock_response
        mock_session_func.return_value = mock_session

        client = UniFiClient("https://controller.local")
        client.get("rest/networkconf")

        # Verify URL construction
        call_args = mock_session.request.call_args
        url = call_args[0][1]
        assert "controller.local" in url
        assert "/api/s/" in url
        assert "rest/networkconf" in url

    @patch("shared.unifi_client.get_authenticated_session")
    def test_verify_ssl_respected_in_requests(self, mock_session_func):
        """verify_ssl parameter is passed to session requests."""
        mock_response = MagicMock()
        mock_response.json.return_value = {"data": []}
        mock_session = MagicMock()
        mock_session.request.return_value = mock_response
        mock_session_func.return_value = mock_session

        client = UniFiClient("https://controller.local", verify_ssl=False)
        client.get("rest/networkconf")

        call_kwargs = mock_session.request.call_args[1]
        assert call_kwargs["verify"] is False
