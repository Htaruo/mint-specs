# 16 — Engineering Principles

**Purpose:** State proven rules that guide implementation and maintenance.

**Confidence note:** initial principles verified against the handoff instructions, Git guidance, and placeholder requirements on 2026-11-23. The code wins (see 16).

1. **Document evidence, not guesses.** Empty repositories cannot justify architecture, incidents, or
   performance claims; invented guidance sends implementation in the wrong direction.
2. **Make privacy requirements executable.** “Retention limits” and “no per-user trails” must become
   enforced data and operational rules; otherwise a stated privacy promise can silently fail.
3. **Keep changes in the owning repository.** Separating API, web, and specs changes makes review,
   release, and rollback boundaries visible.
4. **Use precise imperative commits.** The required scope format makes history searchable and helps
   future engineers reconstruct why a change happened.

Trust the code over any document, including this one.
