"""Bootstrap phase tests.

Validates presence of critical bootstrap artifacts and basic script invariants.
"""

from pathlib import Path

BASE = Path(__file__).resolve().parent.parent


def test_bootstrap_scripts_exist() -> None:
    """Ensure bootstrap install and adoption scripts exist."""
    assert (BASE / "01_bootstrap" / "install-unifi-controller.sh").exists()
    # adoption script lives under the unifi subdirectory
    assert (BASE / "01_bootstrap" / "unifi" / "adopt_devices.py").exists()


def test_vlan_stubs_present() -> None:
    """Ensure VLAN stubs JSON exists and contains expected keys."""
    path = BASE / "01_bootstrap" / "vlan-stubs.json"
    assert path.exists()
    content = path.read_text(encoding="utf-8")
    assert '"vlan"' in content
