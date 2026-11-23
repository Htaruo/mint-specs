# 05 — Debugging Playbook

**Purpose:** Provide fast, evidence-based diagnosis of runtime failures.

**Confidence note:** no runtime, logs, tests, or exact error messages exist in the workspace on 2026-11-23. The code wins (see 16).

## Initial procedure

1. Reproduce the issue and capture the exact message, request, user role, and timestamp.
2. Check the application logs and deployment health once those systems exist.
3. Reduce the failure to a focused test before changing code.
4. Record the cause and fix in 06.

Do not guess from a generic symptom. Miss → a plausible workaround can hide the actual failure
and make the next incident harder to diagnose.
