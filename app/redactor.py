#!/usr/bin/env python3
"""PII Redactor: Presidio-first, regex fallback (Bauer paranoia)

Redacts sensitive information from logs, configs, and audit trails:
- IP addresses (IPv4, IPv6)
- MAC addresses (00:11:22:33:44:55)
- Email addresses
- Phone numbers
- Serial numbers (BIOS, HW identifiers)

Trifecta Compliance: Bauer (No PII/Secrets in Docs)
"""

import re
import logging
from typing import Optional

try:
    from presidio_analyzer import AnalyzerEngine
    from presidio_anonymizer import AnonymizerEngine, AnalyzerResult  # noqa: F401

    PRESIDIO_AVAILABLE = True
except ImportError:  # pragma: no cover
    PRESIDIO_AVAILABLE = False
    AnalyzerEngine = AnalyzerResult = None  # type: ignore

if not PRESIDIO_AVAILABLE:
    logging.warning(
        "Presidio unavailable—using regex fallback. "
        "Install: pip install presidio-analyzer presidio-anonymizer"
    )

# Regex patterns for common PII/secrets
PATTERNS = {
    "ipv4": r"\b(?:\d{1,3}\.){3}\d{1,3}\b",
    "ipv6": r"(?:[0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}",
    "mac": r"\b(?:[0-9A-Fa-f]{2}[:-]){5}(?:[0-9A-Fa-f]{2})\b",
    "email": r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b",
    "phone": r"\b(?:\+1|1)?[-.]?\(?[0-9]{3}\)?[-.]?[0-9]{3}[-.]?[0-9]{4}\b",
    "serial": r"(?:SN|Serial|S/N):?\s*([A-Z0-9]{8,})",
    "uuid": r"\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b",
    "api_key": r"(?:api[_-]?key|token|secret)\s*[:=]\s*[A-Za-z0-9+/=]{20,}",
    "password": r"(?:password|passwd|pwd)\s*[:=]\s*[^\s]+",
}


def redact_pii(text: str, method: str = "auto") -> str:
    """Redact PII from text.

    Args:
        text: Input text to redact
        method: "presidio" (requires library), "regex", or "auto" (try Presidio, fallback to regex)

    Returns:
        Redacted text with PII replaced by [REDACTED]
    """
    if method == "auto":
        method = "presidio" if PRESIDIO_AVAILABLE else "regex"

    if method == "presidio" and PRESIDIO_AVAILABLE:
        return _redact_presidio(text)
    else:
        return _redact_regex(text)


def _redact_presidio(text: str) -> str:
    """Redact using Presidio Analyzer + Anonymizer (most accurate)."""
    try:
        from presidio_analyzer import AnalyzerEngine
        from presidio_anonymizer import AnonymizerEngine

        analyzer = AnalyzerEngine()
        anonymizer = AnonymizerEngine()

        # Analyze for multiple entity types
        results = analyzer.analyze(
            text=text,
            entities=[
                "IP_ADDRESS",
                "EMAIL_ADDRESS",
                "PHONE_NUMBER",
                "PERSON",
                "DOMAIN",
            ],
            language="en",
        )

        # Anonymize all detected entities
        redacted = anonymizer.anonymize(text=text, analyzer_results=results).text

        # Apply additional regex for MAC addresses (Presidio doesn't catch these)
        redacted = re.sub(
            r"\b(?:[0-9A-Fa-f]{2}[:-]){5}(?:[0-9A-Fa-f]{2})\b",
            "[REDACTED]",
            redacted,
            flags=re.IGNORECASE,
        )

        return redacted

    except Exception as e:
        logging.warning(f"Presidio redaction failed: {e}. Falling back to regex.")
        return _redact_regex(text)


def _redact_regex(text: str) -> str:
    """Redact using regex patterns (fallback method)."""
    redacted = text

    # Apply all patterns
    for pattern_name, pattern in PATTERNS.items():
        redacted = re.sub(pattern, "[REDACTED]", redacted, flags=re.IGNORECASE)

    return redacted


def redact_file(filepath: str, output_filepath: Optional[str] = None) -> str:
    """Redact PII from a file.

    Args:
        filepath: Path to file to redact
        output_filepath: Optional path to write redacted content (if None, returns string)

    Returns:
        Redacted content as string

    Raises:
        FileNotFoundError: If input file not found
    """
    with open(filepath, "r", encoding="utf-8", errors="replace") as f:
        content = f.read()

    redacted_content = redact_pii(content)

    if output_filepath:
        with open(output_filepath, "w", encoding="utf-8") as f:
            f.write(redacted_content)
        logging.info(f"Redacted content written to: {output_filepath}")

    return redacted_content


def is_pii_present(text: str) -> bool:
    """Check if text contains potential PII.

    Args:
        text: Text to check

    Returns:
        True if PII patterns detected, False otherwise
    """
    for pattern in PATTERNS.values():
        if re.search(pattern, text, flags=re.IGNORECASE):
            return True
    return False


if __name__ == "__main__":
    # Example usage
    test_text = """
    Server: rylan-dc (10.0.10.10)
    MAC: 00:11:22:33:44:55
    Email: admin@rylan.internal
    Serial: SN-ABC123XYZ456
    API Key: secret_key_abcdefghijklmnopqrst
    """

    print("Original:")
    print(test_text)
    print("\nRedacted:")
    print(redact_pii(test_text))
