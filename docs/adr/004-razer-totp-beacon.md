# ADR 004: Razer Phone 2 → Physical TOTP Beacon (2025)

## Status
Accepted — the only surviving feature.

## Decision
- Aegis Authenticator (offline APK) for UniFi SSO + Samba AD TOTP
- Static IP 10.0.30.45 (MAC fixed in UniFi)
- Termux P1 ticket buzzer (5-minute poll)
- USB-C tethered → PoE splitter → immortal power

## Rejected
- FIDO2 roaming key → impossible on Android 9
- Chroma RGB → SDK dead since 2021
- Local LLM → thermal death
- QR Beacon / Panic Button → moved to future ADRs

This is the line between nostalgia and production. We stay on the right side.
