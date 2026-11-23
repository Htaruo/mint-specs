# 04 — Change Rules

**Purpose:** Track mirrored definitions that must change together.

**Confidence note:** no implementation or lockstep set was found in the workspace on 2026-11-23. The code wins (see 16).

No constants, enums, registries, column lists, error codes, or mirrored types are currently
verifiable. When one is introduced, list every copy here, record the invariant, and test all
consumers. Miss → one copy drifts and clients or persisted data become incompatible.

Re-test API contracts, authentication, persistence, and client behavior whenever a listed set
changes.
