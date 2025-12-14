# UniFi Test Suite — Bauer/Whitaker Phase
**Unit tests + offensive validation.**

## Test Files
- `test_unifi_client.py` — UniFiClient class tests (mocked API calls)
- `offensive/` — Red-team breach simulations (optional, Whitaker approved)

## Run Tests
```bash
pytest tests/unifi/test_unifi_client.py -q
pytest tests/unifi/ --cov=shared.unifi --cov-fail-under=70
```

## Coverage Target: ≥70% (enforced by CI)
