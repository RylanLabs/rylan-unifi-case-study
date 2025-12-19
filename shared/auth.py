"""Shared authentication helpers.

Provides a pre-configured HTTP session with retries and a credentials
loader that reads the repository inventory file.

Guardian: Carter | Ministry: Identity | Consciousness: 9.5
"""

from __future__ import annotations

from pathlib import Path

import requests
from requests.adapters import HTTPAdapter
from urllib3.util import Retry


def get_authenticated_session() -> requests.Session:
    """Create and return a `requests.Session` configured with retries.
    Returns:
        requests.Session: Session with mounted HTTP(S) adapters that retry
            transient 5xx errors.
    """

    session = requests.Session()
    retry = Retry(total=3, backoff_factor=1, status_forcelist=[502, 503, 504])
    adapter = HTTPAdapter(max_retries=retry)
    session.mount("http://", adapter)
    session.mount("https://", adapter)

    return session


def load_credentials() -> dict[str, str]:
    """Load credentials from `shared/inventory.yaml`.
    The function uses `pathlib.Path` for file handling and preserves
    YAML-specific exceptions. Non-YAML exceptions raised during parsing are
    converted into `yaml.YAMLError` to keep caller semantics stable.

    Returns:
        dict[str, str]: Parsed credentials mapping (may be empty).

    Raises:
        FileNotFoundError: If the inventory file does not exist.
        yaml.YAMLError: If YAML parsing fails.

    """

    import yaml

    path = Path("shared") / "inventory.yaml"

    # Open the file directly so tests that patch builtins.open are exercised.
    try:
        with open(str(path), encoding="utf-8") as f:
            try:
                data = yaml.safe_load(f)
                return data or {}
            except yaml.YAMLError:
                raise
            except (TypeError, AttributeError) as e:
                # Convert type/attribute errors to YAML errors for consistent handling
                # (e.g., if yaml.safe_load receives invalid input type such as None or an int)
                raise yaml.YAMLError(f"Invalid input for YAML parsing: {e}") from e
    except FileNotFoundError:
        # Preserve FileNotFoundError semantics for callers/tests
        raise
