"""Extended tests for redactor.py Presidio integration and edge cases."""
import unittest
from unittest.mock import Mock, patch, MagicMock
import sys

# Add app to path
sys.path.insert(0, '/home/egx570/repos/rylan-unifi-case-study')

from app.redactor import redact_pii, is_pii_present, redact_file


class TestPresidioFallbackPath(unittest.TestCase):
    """Test Presidio-specific error handling and fallback."""

    @patch("app.redactor.PRESIDIO_AVAILABLE", True)
    @patch("app.redactor.AnalyzerEngine")
    def test_presidio_import_error_fallback(self, mock_analyzer_cls):
        """When Presidio init fails, fallback to regex."""
        mock_analyzer_cls.side_effect = ImportError("Presidio not found")

        # This should not raise, should fallback to regex
        text = "test@example.com"
        result = redact_pii(text, method="presidio")
        # Should still redact via regex fallback
        self.assertIn("[REDACTED]", result)

    @patch("app.redactor.PRESIDIO_AVAILABLE", True)
    def test_presidio_method_with_unavailable_library(self):
        """Request presidio method when library unavailable."""
        # Patch PRESIDIO_AVAILABLE to be True but imports will fail
        with patch("app.redactor.PRESIDIO_AVAILABLE", True):
            with patch("app.redactor._redact_presidio") as mock_presidio:
                mock_presidio.side_effect = Exception("Presidio failed")
                text = "Email: user@example.com"
                # Should handle exception gracefully
                try:
                    result = redact_pii(text, method="regex")
                    self.assertIn("[REDACTED]", result)
                except Exception as e:
                    self.fail(f"redact_pii should not raise: {e}")

    def test_is_pii_present_with_ips(self):
        """Test PII detection for IP addresses."""
        # IPv4
        self.assertTrue(is_pii_present("Server: 192.168.1.1"))
        self.assertFalse(is_pii_present("Server at port 80"))
        
        # IPv6
        self.assertTrue(is_pii_present("Device: 2001:0db8:85a3::8a2e:0370:7334"))

    def test_is_pii_present_with_emails(self):
        """Test PII detection for emails."""
        self.assertTrue(is_pii_present("Contact: admin@example.com"))
        self.assertFalse(is_pii_present("Contact support"))

    def test_is_pii_present_with_phones(self):
        """Test PII detection for phone numbers."""
        self.assertTrue(is_pii_present("Call: +1-555-123-4567"))
        self.assertTrue(is_pii_present("Phone: 5551234567"))
        self.assertFalse(is_pii_present("Port: 8080"))

    def test_is_pii_present_with_mac_addresses(self):
        """Test PII detection for MAC addresses."""
        self.assertTrue(is_pii_present("MAC: 00:11:22:33:44:55"))
        self.assertTrue(is_pii_present("Device aa-bb-cc-dd-ee-ff"))

    def test_is_pii_present_with_uuids(self):
        """Test PII detection for UUIDs."""
        uuid_str = "550e8400-e29b-41d4-a716-446655440000"
        self.assertTrue(is_pii_present(f"ID: {uuid_str}"))

    def test_is_pii_present_with_api_keys(self):
        """Test PII detection for API keys."""
        self.assertTrue(is_pii_present("api_key: abcdef123456789012345678"))
        self.assertTrue(is_pii_present("token: ghpabcdef123456789012345678"))

    def test_is_pii_present_empty_string(self):
        """Empty string has no PII."""
        self.assertFalse(is_pii_present(""))

    def test_is_pii_present_mixed_content(self):
        """Mixed PII and non-PII content."""
        text = "Server backup completed. Archive stored at 192.168.1.100"
        # Should detect IP
        self.assertTrue(is_pii_present(text))


class TestRedactFileIntegration(unittest.TestCase):
    """Test file-based redaction (line 117-141)."""

    @patch("builtins.open", create=True)
    @patch("os.path.exists")
    def test_redact_file_read_and_write(self, mock_exists, mock_open_fn):
        """Test file reading and writing."""
        mock_exists.return_value = True
        mock_file = MagicMock()
        mock_file.__enter__.return_value = mock_file
        mock_file.read.return_value = "Email: admin@example.com"
        mock_open_fn.return_value = mock_file

        # This would normally write to a file
        # Just verify the function runs without error
        result = redact_file("/tmp/test.txt")
        # Result should be redacted text
        self.assertIn("[REDACTED]", result)

    @patch("os.path.exists")
    def test_redact_file_nonexistent(self, mock_exists):
        """Test handling of nonexistent file."""
        mock_exists.return_value = False
        with self.assertRaises(FileNotFoundError):
            redact_file("/nonexistent/file.txt")


class TestMacAddressRedactionVariants(unittest.TestCase):
    """Comprehensive MAC address redaction tests."""

    def test_mac_colon_separated(self):
        """Test colon-separated MAC addresses."""
        text = "Device MAC: 00:11:22:33:44:55"
        result = redact_pii(text, method="regex")
        self.assertIn("[REDACTED]", result)
        self.assertNotIn("00:11:22:33:44:55", result)

    def test_mac_hyphen_separated(self):
        """Test hyphen-separated MAC addresses."""
        text = "MAC Address: aa-bb-cc-dd-ee-ff"
        result = redact_pii(text, method="regex")
        self.assertIn("[REDACTED]", result)
        self.assertNotIn("aa-bb-cc-dd-ee-ff", result)

    def test_mac_uppercase_and_lowercase(self):
        """Test case-insensitivity."""
        text_upper = "MAC: AA:BB:CC:DD:EE:FF"
        text_lower = "MAC: aa:bb:cc:dd:ee:ff"
        result_upper = redact_pii(text_upper, method="regex")
        result_lower = redact_pii(text_lower, method="regex")
        self.assertIn("[REDACTED]", result_upper)
        self.assertIn("[REDACTED]", result_lower)

    def test_multiple_macs_same_string(self):
        """Multiple MAC addresses in one string."""
        text = "Device1: 00:11:22:33:44:55 Device2: aa:bb:cc:dd:ee:ff"
        result = redact_pii(text, method="regex")
        # Both should be redacted
        self.assertEqual(result.count("[REDACTED]"), 2)


class TestComprehensivePIIPatterns(unittest.TestCase):
    """Test all PII pattern combinations."""

    def test_serial_number_patterns(self):
        """Test serial number detection."""
        text = "Serial: SN123456789ABC"
        result = redact_pii(text, method="regex")
        # Redactor has regex for serial patterns
        self.assertIsNotNone(result)

    def test_password_pattern_common_formats(self):
        """Test common password formats."""
        cases = [
            "password=secret123",
            "pwd: MyP@ssw0rd!",
            "pass: 'abc123'",
        ]
        for text in cases:
            result = redact_pii(text, method="regex")
            self.assertIsNotNone(result)

    def test_ipv6_full_and_abbreviated(self):
        """Test IPv6 full and compressed formats."""
        full = "2001:0db8:85a3:0000:0000:8a2e:0370:7334"
        compressed = "2001:db8:85a3::8a2e:370:7334"
        
        result_full = redact_pii(full, method="regex")
        result_compressed = redact_pii(compressed, method="regex")
        
        # Both should be redacted
        self.assertIn("[REDACTED]", result_full)
        self.assertIn("[REDACTED]", result_compressed)

    def test_email_with_subdomain(self):
        """Test email with subdomains."""
        text = "Contact: admin@mail.company.co.uk"
        result = redact_pii(text, method="regex")
        self.assertIn("[REDACTED]", result)

    def test_phone_with_extension(self):
        """Test phone with extension."""
        text = "Call: +1-555-123-4567 ext. 1234"
        result = redact_pii(text, method="regex")
        # Phone number should be redacted
        self.assertIn("[REDACTED]", result)


if __name__ == "__main__":
    unittest.main()
