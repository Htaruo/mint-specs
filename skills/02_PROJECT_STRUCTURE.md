# 02 — Project Structure

**Purpose:** Explain where new code and documentation belong.

**Confidence note:** verified against the workspace contents on 2026-11-23. The code wins (see 16).

## Current tree

```text
mint-ecosystem/
  mint-api/       empty repository
  mint-web/       empty repository
  mint-specs/
    business-logic-v1.0.md
    git-guidelines.md
    sense-making.md
    skills/
```

Put backend code in `mint-api`, web code in `mint-web`, and shared requirements and handoff
documents in `mint-specs`. Do not place application code in `mint-specs`.

Naming conventions are not yet established. Add them here when code demonstrates a stable
convention; do not infer them from placeholder text.
