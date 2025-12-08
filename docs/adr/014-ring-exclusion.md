# ADR-014: Ring Doorbell Exclusion from v∞.1.2

**Status:** Accepted
**Date:** 2025-12-04
**Context:** v∞.1.2-iot-ready — Explicitly excluding Ring doorbell from IoT integration

## Context

Ring doorbells are popular IoT security devices offering:
- Video doorbell with cloud recording
- Motion detection and alerts
- Two-way audio communication
- Mobile app integration

However, Ring devices present significant security and privacy concerns incompatible with fortress principles.

## Decision

**Exclude Ring doorbell from v∞.1.2 IoT integration.** Defer to v∞.2.x with local NVR alternative (e.g., Reolink).

## Rationale

### Security Concerns
1. **Law Enforcement Access**: Ring has established warrant-less data sharing with police departments
2. **High PII Content**: Video and audio recordings contain sensitive personally identifiable information
3. **Deauth Vulnerabilities**: WiFi-based Ring devices susceptible to deauthentication attacks (CVE-2019-9422)
4. **Mandatory Cloud Storage**: No local-only recording option; all footage routed through Amazon servers
5. **Third-party Integrations**: Alexa integration creates additional attack surface

### Bauer Compliance Failure
- **Trust nothing, verify everything**: Cannot verify Ring cloud processing or access controls
- **Zero PII leakage**: Video/audio recordings inherently contain PII, no local redaction possible
- **Audit logging**: No access to Ring server-side audit trails

## Alternatives Considered

1. **Ring on VLAN 95 (rejected)**: Still requires cloud, doesn't address PII concerns
2. **Ring with local NVR bridge (rejected)**: Ring doesn't support RTSP local streaming
3. **Reolink doorbell + local NVR (recommended for v∞.2.x)**:
   - ONVIF/RTSP support for local recording
   - No mandatory cloud dependency
   - Motion detection on-device
   - Integrates with Blue Iris / Frigate NVR

## Consequences

### Positive
- **Bauer compliant**: No PII video/audio stored on third-party servers
- **Carter compliant**: Local NVR maintains identity control
- **Reduced attack surface**: Eliminates Ring cloud dependency

### Negative
- **Delayed doorbell feature**: No video doorbell until v∞.2.x
- **Higher upfront cost**: Reolink + NVR more expensive than Ring subscription

## Implementation Timeline

- **v∞.1.2 (current)**: Ring explicitly excluded from IoT integration
  - **v∞.2.x (future)**: Evaluate Reolink RVD800-NVR doorbell with local NVR
  - Blue Iris on Windows VM or Frigate on LXC
  - Use guest-iot (VLAN 90) or iot-isolated VLAN 95 depending on deployment
  - No internet access for doorbell itself

## References
- Bauer (2005): "Trust nothing, verify everything"
- Ring police partnerships: [EFF Report 2022](https://www.eff.org/deeplinks/2022/07/ring-reveals-it-gave-videos-police-without-user-consent-or-warrant-11-times-year)
- CVE-2019-9422: Ring Video Doorbell WiFi deauth vulnerability
- Reolink ONVIF support: <https://reolink.com/onvif-ip-camera/>
