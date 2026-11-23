# 14 — Developer Workflows

**Purpose:** Give contributors repeatable setup, change, verification, and handoff recipes.

**Confidence note:** verified against the three repository directories and Git guidance on 2026-11-23. The code wins (see 16).

## Initial repository workflow

1. Confirm the target repository: `mint-api`, `mint-web`, or `mint-specs`.
2. Read its applicable `AGENTS.md` and this skills set.
3. Make the smallest change in the owning repository.
4. Run the repository's documented formatter, linter, build, and tests; none are defined yet.
5. Inspect `git diff` and `git status`.
6. Use the required imperative commit format from `git-guidelines.md` if committing.

For requirements changes, update the relevant skill document and `00_INDEX.md` confidence date.
For unverified knowledge, add it to `INBOX.md`. Add what surprised you to `INBOX.md`.
