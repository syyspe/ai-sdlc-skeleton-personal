---
name: secure-api-review
description: Use when designing or implementing an API endpoint (Stage 2 design, Stage 3 build, or Stage 5 review) to check it against this project's baseline security requirements. Trigger on new/changed routes, controllers, or handlers.
---

# Secure API Review

Apply this checklist to every API endpoint that's new or changed. This is a
baseline — add project-specific requirements below rather than replacing
these.

## Requirements

1. **Authentication** — every endpoint requires a valid gateway JWT unless
   it's explicitly on the public allowlist (`<link/path to allowlist>`). No
   endpoint should silently fall back to unauthenticated.
2. **Input validation** — request bodies and query params are validated
   against the OpenAPI schema before any business logic runs. Reject on
   validation failure; don't coerce silently.
3. **Audit events** — any endpoint that changes state emits an audit event
   (`<event schema/location>`) with actor, action, and target. Read-only
   endpoints are exempt.
4. **PII handling** — PII fields (`<list or reference to PII field registry>`)
   are never written to logs or included in error messages returned to the
   client. Check both the happy path and error handlers.

## When this skill flags something

- During **Design**: note the concern in the spec's "Policy flags" section
  and surface it to the security policy owner before the product owner
  approves.
- During **Build**: fix it before the plan is considered complete.
- During **Review**: this is always an "Important" finding per `REVIEW.md`,
  never a nit.

## Project-specific additions

`<add any endpoint requirements specific to this repo here>`
