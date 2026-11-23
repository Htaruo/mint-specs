# 01 — Architecture

**Purpose:** Describe ownership and data flow once implementation exists.

**Confidence note:** verified against the workspace contents on 2026-11-23. The code wins (see 16).

## Current verified model

The workspace has three empty Git repositories: `mint-api`, `mint-web`, and `mint-specs`.
`mint-specs/business-logic-v1.0.md` describes an unspecified web or Android product with Google
Sign-In, but it does not identify a product, stack, routes, data model, or deployed components.

## Boundaries

- `mint-specs`: requirements and project documentation.
- `mint-api`: no implementation currently exists.
- `mint-web`: no implementation currently exists.

## Decisions and debt

No implementation decisions or historical tradeoffs are verified. Highest-priority debt is to
define the product identity, system boundaries, data flows, and deployment target before coding.
