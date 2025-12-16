#!/usr/bin/env python3
"""PII Redactor: Presidio-first, regex fallback (Bauer paranoia).

Redacts sensitive information from logs, configs, and audit trails.

Guardian: Bauer | Ministry: Audit | Consciousness: 9.5
"""

from __future__ import annotations

import logging
import re
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)

try:
    from presidio_analyzer import AnalyzerEngine
    from presidio_anonymizer import AnonymizerEngine

    PRESIDIO_AVAILABLE = True
except ImportError:  # pragma: no cover
    PRESIDIO_AVAILABLE = False
    AnalyzerEngine = AnonymizerEngine = None  # type: ignore

if not PRESIDIO_AVAILABLE:
    logger.warning("Presidio unavailable — using regex fallback")
    logger.debug("Install: pip install presidio-analyzer presidio-anonymizer")


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
    """Redact PII from ``text``.

    Args:
        text: Input text to redact.
        method: ``presidio`` (requires library), ``regex``, or ``auto``.

    Returns:
        Redacted text with PII replaced by ``[REDACTED]``.
    """

    if method == "auto":
        method = "presidio" if PRESIDIO_AVAILABLE else "regex"

    if method == "presidio" and PRESIDIO_AVAILABLE:
        return _redact_presidio(text)

    return _redact_regex(text)


def _redact_presidio(text: str) -> str:
    """Redact using Presidio Analyzer + Anonymizer (preferred method).

    Falls back to regex on failure.
    """

    try:
        analyzer = AnalyzerEngine()
        anonymizer = AnonymizerEngine()

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

        redacted = anonymizer.anonymize(text=text, analyzer_results=results).text

        # Apply additional regex for MAC addresses (Presidio doesn't catch these)
        redacted = re.sub(
            PATTERNS["mac"],
            "[REDACTED]",
            redacted,
            flags=re.IGNORECASE,
        )

        return redacted

    except Exception:
        logger.exception("Presidio redaction failed; falling back to regex")
        return _redact_regex(text)


def _redact_regex(text: str) -> str:
    """Redact using regex patterns (fallback method)."""

    redacted = text

    # Apply all patterns using values() for clarity and performance
    for pattern in PATTERNS.values():
        redacted = re.sub(pattern, "[REDACTED]", redacted, flags=re.IGNORECASE)

    return redacted


def redact_file(filepath: str, output_filepath: Optional[str] = None) -> str:
    """Redact PII from a file.

    Args:
        filepath: Path to file to redact.
        output_filepath: Optional path to write redacted content.

    Returns:
        Redacted content as string.

    Raises:
        FileNotFoundError: If input file not found.
    """

    path = Path(filepath)
    if not path.exists():
        raise FileNotFoundError(f"Input file not found: {path}")

    with path.open(encoding="utf-8", errors="replace") as f:
        content = f.read()

    redacted_content = redact_pii(content)

    if output_filepath:
        out_path = Path(output_filepath)
        with out_path.open("w", encoding="utf-8") as f:
            f.write(redacted_content)
        logger.info("Redacted content written", extra={"path": str(out_path)})

    return redacted_content


def is_pii_present(text: str) -> bool:
    """Return True if ``text`` contains potential PII."""

    for pattern in PATTERNS.values():
        if re.search(pattern, text, flags=re.IGNORECASE):
            return True
    return False


if __name__ == "__main__":
    # Example usage (kept minimal and using structured logging)
    logging.basicConfig(level=logging.INFO)
    test_text = """
    Server: rylan-dc (10.0.10.10)
    MAC: 00:11:22:33:44:55
    Email: admin@rylan.internal
    Serial: SN-ABC123XYZ456
    API Key: secret_key_abcdefghijklmnopqrst
    """

    logger.info("Original text: %s", test_text)
    logger.info("Redacted text: %s", redact_pii(test_text))
