# UniFi Python Abstractions — Carter/Bauer
**Object-oriented UniFi REST API wrappers.**

## Modules
- `__init__.py` — Package marker (docstring + imports)
- `auth.py` — Session mgmt, credential loading, retry logic
- `unifi_client.py` — UniFiClient class (device listing, adoption, network mgmt)

## Quick Start
```python
from shared.unifi import UniFiClient
c = UniFiClient("https://10.0.1.20", verify_ssl=False)
c.login("admin", "secret")
devices = c.get_devices()
c.adopt_device("aa:bb:cc:dd:ee:ff")
```

## Zero PII: All redacted on output (app/redactor.py)
