"""Bootstrap phase tests.

Validates presence of critical bootstrap artifacts and basic script invariants.
"""

from pathlib import Path

# Templates live under templates/, tests under template_tests; resolve to repo root
BASE = Path(__file__).resolve().parent.parent.parent


def test_bootstrap_scripts_exist() -> None:
    assert (BASE / "01_bootstrap" / "install-unifi-controller.sh").exists()
    # adoption script lives under the unifi subdirectory in the canonical bootstrap area
    assert (BASE / "01_bootstrap" / "unifi" / "adopt_devices.py").exists()


def test_vlan_stubs_present() -> None:
    path = BASE / "01_bootstrap" / "vlan-stubs.json"
    assert path.exists()
    content = path.read_text(encoding="utf-8")
    assert '"vlan"' in content
