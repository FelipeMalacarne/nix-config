---
name: product-engineering
description: Use for SaaS/product features, user flows, dashboards, auth, billing, permissions, onboarding, and customer-facing behavior.
---

# Product Engineering

Use this skill when a task affects product behavior, user experience, or business workflows.

## Product Checklist

- Who is the user?
- What is the user trying to accomplish?
- What is the smallest useful version?
- What data is created, read, updated, or deleted?
- What permissions or tenant boundaries apply?
- What loading, empty, error, and success states exist?
- What needs to be tested before shipping?

## Engineering Checklist

- Keep frontend, API, validation, database, and background jobs consistent.
- Avoid client-only enforcement for security-sensitive rules.
- Prefer server-side validation and explicit authorization checks.
- Consider migrations, seed data, queues, webhooks, emails, and observability when relevant.
- Make failure modes visible to users and diagnosable for developers.

## Output

When proposing a solution, include:

- Product behavior
- Implementation boundary
- Data model or API impact
- Verification plan
- Risk notes
