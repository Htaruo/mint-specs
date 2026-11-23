# 09 — Security

**Purpose:** Capture the threat model and security checks for every change.

**Confidence note:** verified against the security/privacy requirement in `business-logic-v1.0.md` on 2026-11-23. Implementation details are unverified. The code wins (see 16).

## Verified requirements

- Google Sign-In authentication is required.
- Security and privacy by design is required.
- The requirements mention Data Privacy Act compliance, location protection, retention limits,
  no per-user trails, aggregation thresholds, and consent for data resale.

## Missing controls

There is no implementation to verify token validation, authorization, secret storage, injection
defense, debug gates, audit behavior, deletion, or consent enforcement. Treat these as release
blockers until designed, implemented, and tested. Never commit secret values; document only
environment-variable names.
