#!/usr/bin/env python3
"""
UniFi Device Auto-Adoption Script

Automatically discovers and adopts UniFi devices (USG, switches, APs) using
the UniFi Controller API with aiounifi library.

Requirements:
    - aiounifi>=73
    - Local admin account (no 2FA)
    - Controller URL in shared/inventory.yaml

Usage:
    python adopt-devices.py
    python adopt-devices.py --dry-run
    python adopt-devices.py --site-name "default"
"""

import asyncio
import argparse
import sys
from pathlib import Path
from typing import List, Dict, Any

try:
    import yaml
    from aiounifi.controller import Controller
    from aiounifi.models.device import Device
    from aiohttp import ClientSession, ClientTimeout
except ImportError as e:
    print(f"❌ Missing required package: {e}")
    print("Install with: pip install aiounifi pyyaml aiohttp")
    sys.exit(1)


class UniFiAdopter:
    """Handles UniFi device discovery and adoption"""
    
    def __init__(self, controller_url: str, username: str, password: str, 
                 site: str = "default", dry_run: bool = False):
        self.controller_url = controller_url
        self.username = username
        self.password = password
        self.site = site
        self.dry_run = dry_run
        self.controller: Controller = None
        
    async def connect(self):
        """Establish connection to UniFi Controller"""
        print(f"🔌 Connecting to {self.controller_url} (site: {self.site})...")
        
        session = ClientSession(timeout=ClientTimeout(total=30))
        
        self.controller = Controller(
            host=self.controller_url.replace("https://", "").replace("http://", "").split(":")[0],
            username=self.username,
            password=self.password,
            port=8443,
            site=self.site,
            session=session,
            ssl_context=False  # Accept self-signed cert
        )
        
        await self.controller.login()
        print("✅ Connected to UniFi Controller")
        
    async def discover_devices(self) -> List[Device]:
        """Discover all UniFi devices on network"""
        print("\n🔍 Discovering devices...")
        
        await self.controller.sites()
        await self.controller.initialize()
        
        devices = list(self.controller.devices.values())
        
        print(f"📡 Found {len(devices)} device(s):")
        for dev in devices:
            status = "✅ Adopted" if dev.state == 1 else "⏳ Pending"
            print(f"  {status} {dev.model:20s} {dev.mac:17s} {dev.ip or 'N/A':15s} {dev.name or 'Unnamed'}")
        
        return devices
        
    async def adopt_device(self, device: Device) -> bool:
        """Adopt a single device"""
        if device.state == 1:
            print(f"  ⏭️  {device.model} ({device.mac}) already adopted")
            return True
            
        if self.dry_run:
            print(f"  🔍 [DRY-RUN] Would adopt {device.model} ({device.mac})")
            return True
            
        try:
            print(f"  🔄 Adopting {device.model} ({device.mac})...")
            
            # Adopt device via Controller API
            await self.controller.request(
                method="post",
                path=f"s/{self.site}/cmd/devmgr",
                json={
                    "cmd": "adopt",
                    "mac": device.mac
                }
            )
            
            # Wait for adoption to complete
            await asyncio.sleep(5)
            
            # Verify adoption
            await self.controller.devices.update()
            updated_device = self.controller.devices.get(device.mac)
            
            if updated_device and updated_device.state == 1:
                print(f"  ✅ Successfully adopted {device.model} ({device.mac})")
                return True
            else:
                print(f"  ⚠️  Adoption in progress for {device.model} ({device.mac})")
                return False
                
        except Exception as e:
            print(f"  ❌ Failed to adopt {device.model} ({device.mac}): {e}")
            return False
            
    async def adopt_all(self):
        """Adopt all pending devices"""
        devices = await self.discover_devices()
        
        pending_devices = [dev for dev in devices if dev.state != 1]
        
        if not pending_devices:
            print("\n✅ No devices require adoption")
            return
            
        print(f"\n🚀 Adopting {len(pending_devices)} device(s)...")
        
        results = []
        for device in pending_devices:
            success = await self.adopt_device(device)
            results.append((device, success))
            
        # Summary
        print("\n" + "="*60)
        print("📊 Adoption Summary")
        print("="*60)
        
        successful = sum(1 for _, success in results if success)
        failed = len(results) - successful
        
        print(f"  ✅ Successful: {successful}")
        print(f"  ❌ Failed:     {failed}")
        
        if failed > 0:
            print("\n⚠️  Some devices failed to adopt. Check controller logs.")
            
    async def close(self):
        """Close connection"""
        if self.controller and self.controller.session:
            await self.controller.session.close()


def load_inventory(inventory_path: Path) -> Dict[str, Any]:
    """Load UniFi credentials from inventory.yaml"""
    if not inventory_path.exists():
        print(f"❌ Inventory file not found: {inventory_path}")
        print("Create shared/inventory.yaml with UniFi credentials")
        sys.exit(1)
        
    with open(inventory_path) as f:
        inventory = yaml.safe_load(f)
        
    if "unifi_controller" not in inventory:
        print("❌ 'unifi_controller' section missing in inventory.yaml")
        sys.exit(1)
        
    return inventory["unifi_controller"]


async def main():
    parser = argparse.ArgumentParser(
        description="Auto-adopt UniFi devices",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python adopt-devices.py
  python adopt-devices.py --dry-run
  python adopt-devices.py --site-name "production"
        """
    )
    parser.add_argument("--dry-run", action="store_true", help="Show what would be adopted without making changes")
    parser.add_argument("--site-name", default="default", help="UniFi site name (default: 'default')")
    parser.add_argument("--inventory", default="../shared/inventory.yaml", help="Path to inventory.yaml")
    
    args = parser.parse_args()
    
    # Resolve inventory path
    inventory_path = Path(__file__).parent / args.inventory
    
    print("🚀 UniFi Device Auto-Adoption")
    print("="*60)
    
    if args.dry_run:
        print("⚠️  DRY-RUN MODE: No changes will be made\n")
    
    # Load credentials
    try:
        config = load_inventory(inventory_path)
    except Exception as e:
        print(f"❌ Error loading inventory: {e}")
        sys.exit(1)
    
    # Extract config
    controller_url = config.get("url", "https://10.0.1.1:8443")
    username = config.get("username")
    password = config.get("password")
    
    if not username or not password:
        print("❌ Missing 'username' or 'password' in inventory.yaml unifi_controller section")
        sys.exit(1)
    
    # Run adoption
    adopter = UniFiAdopter(
        controller_url=controller_url,
        username=username,
        password=password,
        site=args.site_name,
        dry_run=args.dry_run
    )
    
    try:
        await adopter.connect()
        await adopter.adopt_all()
    except Exception as e:
        print(f"\n❌ Error during adoption: {e}")
        sys.exit(1)
    finally:
        await adopter.close()
    
    print("\n🎉 Adoption complete!")
    print("\nNext Steps:")
    print("  1. Verify devices in UniFi Controller Web UI")
    print("  2. Configure device names and locations")
    print("  3. Run 02-declarative-config/apply.py to apply VLANs and policy table")


if __name__ == "__main__":
    asyncio.run(main())
