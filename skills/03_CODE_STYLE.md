# 03 — Code Style

**Purpose:** Record conventions that keep code readable and failures visible.

**Confidence note:** verified against `mint-specs/git-guidelines.md` and the workspace contents on 2026-11-23. The code wins (see 16).

## Verified guidance

- Commit summaries use `scope: Imperative summary`, sentence case, and no more than 50 characters.
- Use the most specific product/feature scope; avoid generic `ui:`, `api:`, or `core:` scopes.
- Explain why in a commit body for non-trivial changes.

No language formatter, linter, error model, logging framework, or runtime pattern is present.
Do not silently swallow errors when implementation begins: surface them through the chosen
repository-standard logging or user notification path.
