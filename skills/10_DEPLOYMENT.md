# 10 — Deployment

**Purpose:** Describe release order, deployables, configuration, and rollback.

**Confidence note:** no CI, container, hosting, environment, or release configuration was found on 2026-11-23. The code wins (see 16).

No deployment sequence or release tag convention beyond the commit guidance is verified.
Before the first release, document build commands, required environment-variable names, migration
ordering, health checks, rollback steps, and approval gates for `mint-api` and `mint-web`.
