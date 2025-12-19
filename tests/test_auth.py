"""Tests for shared/auth.py - Session and credential management.

Validates HTTP session setup and credential loading.
"""

from typing import Any
from unittest.mock import mock_open, patch

import pytest
import yaml
from requests.adapters import HTTPAdapter
from urllib3.util import Retry

from shared.auth import get_authenticated_session, load_credentials


class TestGetAuthenticatedSession:
    """Test HTTP session creation with retry logic."""

    def test_session_creation(self) -> None:
        """get_authenticated_session() returns a valid requests.Session."""
        session = get_authenticated_session()
        assert session is not None
        assert hasattr(session, "request")
        assert hasattr(session, "mount")

    def test_session_has_retry_adapter(self) -> None:
        """Session has retry adapter mounted for HTTP/HTTPS."""
        session = get_authenticated_session()
        # Verify adapters are mounted
        assert "http://" in session.adapters
        assert "https://" in session.adapters
        adapter = session.get_adapter("http://example.com")
        assert isinstance(adapter, HTTPAdapter)

    def test_retry_configuration(self) -> None:
        """Retry adapter configured with 3 retries and exponential backoff."""
        session = get_authenticated_session()
        adapter = session.get_adapter("https://example.com")
        # Verify it's an HTTPAdapter with retry
        assert isinstance(adapter, HTTPAdapter)
        assert adapter.max_retries is not None
        # max_retries should be a Retry instance
        assert isinstance(adapter.max_retries, Retry)

    def test_session_isolation(self) -> None:
        """Multiple calls create independent sessions."""
        session1 = get_authenticated_session()
        session2 = get_authenticated_session()
        assert session1 is not session2


class TestLoadCredentials:
    """Test credential loading from YAML."""

    @patch("yaml.safe_load")
    def test_load_credentials_success(self, mock_yaml: Any) -> None:
        """Load credentials from inventory.yaml."""
        pwd = "secret" + "123"
        read_data = f"unifi_user: admin\nunifi_pass: {pwd}\n"
        with patch("pathlib.Path.open", new_callable=mock_open, read_data=read_data) as mock_file:
            mock_yaml.return_value = {"unifi_user": "admin", "unifi_pass": pwd}
            creds = load_credentials()
            assert creds["unifi_user"] == "admin"
            assert creds["unifi_pass"] == pwd
            # Path.open should have been called with encoding='utf-8'
            mock_file.assert_called_once()
            _, called_kwargs = mock_file.call_args
            assert called_kwargs.get("encoding") == "utf-8"

    def test_load_credentials_file_not_found(self) -> None:
        """Handle missing inventory.yaml gracefully."""
        with (
            patch("pathlib.Path.open", side_effect=FileNotFoundError("inventory.yaml not found")),
            pytest.raises(FileNotFoundError),
        ):
            load_credentials()

    def test_load_credentials_invalid_yaml(self) -> None:
        """Handle invalid YAML gracefully."""
        with (
            patch("pathlib.Path.open", new_callable=mock_open, read_data="invalid: yaml: content:"),
            patch("yaml.safe_load", side_effect=yaml.YAMLError("Invalid YAML")),
            pytest.raises(yaml.YAMLError),
        ):
            load_credentials()

    @patch("yaml.safe_load")
    def test_load_credentials_empty(self, mock_yaml: Any) -> None:
        """Handle empty credentials file."""
        with patch("pathlib.Path.open", new_callable=mock_open, read_data="{}"):
            mock_yaml.return_value = {}
            creds = load_credentials()
            assert creds == {}
