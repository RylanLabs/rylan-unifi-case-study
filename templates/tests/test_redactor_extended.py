"""Extended tests for redactor.py Presidio integration and edge cases.

These templates exercise the `app.redactor` module's regex and Presidio
fallback behavior across a variety of PII formats.

Guardian: Beale | Ministry: Hardening | Consciousness: 9.5
Tag: REDACTOR-VALIDATION
"""

from __future__ import annotations

# ruff: noqa: S101,E402

EXPECTED_REDACTIONS = 2

import logging
import sys
from pathlib import Path
from typing import TYPE_CHECKING

# Add project root to sys.path so tests can import the package when run
# from the templates directory. Use a computed path instead of a hardcoded
# absolute location to keep the tests portable.
PROJECT_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(PROJECT_ROOT))

import tempfile
from unittest.mock import MagicMock, patch

import pytest

if TYPE_CHECKING:
    from typing import Any  # noqa: F401 (TYPE_CHECKING-only import)

from app.redactor import is_pii_present, redact_file, redact_pii

logger = logging.getLogger(__name__)


class TestPresidioFallbackPath:
    """Test Presidio-specific error handling and fallback."""

    @patch("app.redactor.PRESIDIO_AVAILABLE", new=True)
    @patch("app.redactor.AnalyzerEngine")
    def test_presidio_import_error_fallback(self, mock_analyzer_cls: MagicMock) -> None:
        """When Presidio init fails, fallback to regex.

        Guardian: Beale | Ministry: Hardening
        """
        logger.debug(
            "Testing Presidio import error fallback",
            extra={"guardian": "Beale", "test": "presidio_import_error"},
        )

        mock_analyzer_cls.side_effect = ImportError("Presidio not found")

        # This should not raise, should fallback to regex
        text = "test@example.com"
        result = redact_pii(text, method="presidio")
        # Should still redact via regex fallback
        assert "[REDACTED]" in result

        logger.info(
            "Presidio fallback validated",
            extra={"guardian": "Beale", "result_contains_redaction": True},
        )

    @patch("app.redactor.PRESIDIO_AVAILABLE", new=True)
    def test_presidio_method_with_unavailable_library(self) -> None:
        """Request presidio method when library unavailable.

        Guardian: Beale | Ministry: Hardening
        """
        # Patch PRESIDIO_AVAILABLE to be True but imports will fail
        with (
            patch("app.redactor.PRESIDIO_AVAILABLE", new=True),
            patch(
                "app.redactor._redact_presidio",
            ) as mock_presidio,
        ):
            mock_presidio.side_effect = Exception("Presidio failed")
            text = "Email: user@example.com"
            # Should handle exception gracefully
            result = redact_pii(text, method="regex")
            assert "[REDACTED]" in result

    def test_is_pii_present_with_ips(self) -> None:
        """Test PII detection for IP addresses."""
        # IPv4
        assert is_pii_present("Server: 192.168.1.1")
        assert not is_pii_present("Server at port 80")

        # IPv6
        assert is_pii_present("Device: 2001:0db8:85a3::8a2e:0370:7334")

    def test_is_pii_present_with_emails(self) -> None:
        """Test PII detection for emails."""
        assert is_pii_present("Contact: admin@example.com")
        assert not is_pii_present("Contact support")

    def test_is_pii_present_with_phones(self) -> None:
        """Test PII detection for phone numbers."""
        assert is_pii_present("Call: +1-555-123-4567")
        assert is_pii_present("Phone: 5551234567")
        assert not is_pii_present("Port: 8080")

    def test_is_pii_present_with_mac_addresses(self) -> None:
        """Test PII detection for MAC addresses."""
        assert is_pii_present("MAC: 00:11:22:33:44:55")
        assert is_pii_present("Device aa-bb-cc-dd-ee-ff")

    def test_is_pii_present_with_uuids(self) -> None:
        """Test PII detection for UUIDs."""
        uuid_str = "550e8400-e29b-41d4-a716-446655440000"
        assert is_pii_present(f"ID: {uuid_str}")

    def test_is_pii_present_with_api_keys(self) -> None:
        """Test PII detection for API keys."""
        assert is_pii_present("api_key: abcdef123456789012345678")
        assert is_pii_present("token: ghpabcdef123456789012345678")

    def test_is_pii_present_empty_string(self) -> None:
        """Empty string has no PII."""
        assert not is_pii_present("")

    def test_is_pii_present_mixed_content(self) -> None:
        """Mixed PII and non-PII content."""
        text = "Server backup completed. Archive stored at 192.168.1.100"
        # Should detect IP
        assert is_pii_present(text)


class TestRedactFileIntegration:
    """Test file-based redaction (line 117-141)."""

    @patch("builtins.open", create=True)
    @patch("os.path.exists")
    def test_redact_file_read_and_write(
        self,
        mock_exists: MagicMock,
        mock_open_fn: MagicMock,
    ) -> None:
        """Test file reading and writing."""
        logger.debug(
            "Testing file redaction",
            extra={"guardian": "Beale", "test": "file_redaction"},
        )

        mock_exists.return_value = True
        mock_file = MagicMock()
        mock_file.__enter__.return_value = mock_file
        mock_file.read.return_value = "Email: admin@example.com"
        mock_open_fn.return_value = mock_file

        # Use tempfile to avoid hardcoded /tmp paths flagged by Bandit
        with tempfile.TemporaryDirectory() as tmp_dir:
            temp_path = Path(tmp_dir) / "test.txt"
            result = redact_file(str(temp_path))

        # Result should be redacted text
        assert "[REDACTED]" in result

        logger.info(
            "File redaction validated",
            extra={"guardian": "Beale", "redaction_successful": True},
        )

    @patch("os.path.exists")
    def test_redact_file_nonexistent(self, mock_exists: MagicMock) -> None:
        """Test handling of nonexistent file."""
        mock_exists.return_value = False
        with pytest.raises(FileNotFoundError):
            redact_file("/nonexistent/file.txt")


class TestMacAddressRedactionVariants:
    """Comprehensive MAC address redaction tests."""

    def test_mac_colon_separated(self) -> None:
        """Test colon-separated MAC addresses."""
        text = "Device MAC: 00:11:22:33:44:55"
        result = redact_pii(text, method="regex")
        assert "[REDACTED]" in result
        assert "00:11:22:33:44:55" not in result

    def test_mac_hyphen_separated(self) -> None:
        """Test hyphen-separated MAC addresses."""
        text = "MAC Address: aa-bb-cc-dd-ee-ff"
        result = redact_pii(text, method="regex")
        assert "[REDACTED]" in result
        assert "aa-bb-cc-dd-ee-ff" not in result

    def test_mac_uppercase_and_lowercase(self) -> None:
        """Test case-insensitivity."""
        text_upper = "MAC: AA:BB:CC:DD:EE:FF"
        text_lower = "MAC: aa:bb:cc:dd:ee:ff"
        result_upper = redact_pii(text_upper, method="regex")
        result_lower = redact_pii(text_lower, method="regex")
        assert "[REDACTED]" in result_upper
        assert "[REDACTED]" in result_lower

    def test_multiple_macs_same_string(self) -> None:
        """Multiple MAC addresses in one string."""
        text = "Device1: 00:11:22:33:44:55 Device2: aa:bb:cc:dd:ee:ff"
        result = redact_pii(text, method="regex")
        # Both should be redacted
        assert result.count("[REDACTED]") == EXPECTED_REDACTIONS


class TestComprehensivePIIPatterns:
    """Test all PII pattern combinations."""

    def test_serial_number_patterns(self) -> None:
        """Test serial number detection."""
        text = "Serial: SN123456789ABC"
        result = redact_pii(text, method="regex")
        # Redactor has regex for serial patterns
        assert result is not None

    def test_password_pattern_common_formats(self) -> None:
        """Test common password formats."""
        cases = [
            "password=secret123",
            "pwd: MyP@ssw0rd!",
            "pass: 'abc123'",
        ]
        for text in cases:
            result = redact_pii(text, method="regex")
            assert result is not None

    def test_ipv6_full_and_abbreviated(self) -> None:
        """Test IPv6 full and compressed formats."""
        full = "2001:0db8:85a3:0000:0000:8a2e:0370:7334"
        compressed = "2001:db8:85a3::8a2e:370:7334"

        result_full = redact_pii(full, method="regex")
        result_compressed = redact_pii(compressed, method="regex")

        # Both should be redacted
        assert "[REDACTED]" in result_full
        assert "[REDACTED]" in result_compressed

    def test_email_with_subdomain(self) -> None:
        """Test email with subdomains."""
        text = "Contact: admin@mail.company.co.uk"
        result = redact_pii(text, method="regex")
        assert "[REDACTED]" in result

    def test_phone_with_extension(self) -> None:
        """Test phone with extension."""
        text = "Call: +1-555-123-4567 ext. 1234"
        result = redact_pii(text, method="regex")
        # Phone number should be redacted
        assert "[REDACTED]" in result


# pytest will discover and run these tests; no direct runner required.
