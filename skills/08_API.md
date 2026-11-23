# 08 — API

**Purpose:** Document the response contract, routes, authorization, and endpoint workflow.

**Confidence note:** no API source, route, validator, or contract exists on 2026-11-23. The code wins (see 16).

No response envelope or route inventory can be verified. Before adding an endpoint, define its
authentication and authorization requirements, input validator, response shape, error codes,
versioning policy, and focused tests. Google Sign-In is a requirement in
`business-logic-v1.0.md`; the token validation boundary remains unspecified.

Miss → accepting client-supplied identity or location data without server-side validation can
break authorization and privacy guarantees.
