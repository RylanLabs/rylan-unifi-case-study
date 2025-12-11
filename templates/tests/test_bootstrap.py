"""Bootstrap phase tests.

Validates presence of critical bootstrap artifacts and basic script invariants.
"""

from pathlib import Path

BASE = Path(__file__).resolve().parent.parent


def test_bootstrap_scripts_exist():
    assert (BASE / "01-bootstrap" / "install-unifi-controller.sh").exists()
    assert (BASE / "01-bootstrap" / "adopt-devices.py").exists()


def test_vlan_stubs_present():
    path = BASE / "01-bootstrap" / "vlan-stubs.json"
    assert path.exists()
    content = path.read_text(encoding="utf-8")
    assert '"vlan"' in content
