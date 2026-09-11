---
name: browser-automation
description: Use for Playwright/browser automation, UI bugs, form flows, auth flows, responsive checks, screenshots, console errors, and end-to-end web verification.
---

# Browser Automation

Use this skill when a task needs real browser feedback through Playwright MCP.

## When To Use

- Reproducing UI bugs
- Testing forms, auth flows, onboarding, checkout, dashboards, and navigation
- Checking responsive behavior
- Capturing screenshots or visual state
- Inspecting browser console errors
- Inspecting failed network requests
- Verifying that a frontend change works in the browser

## Before Opening The Browser

- Identify the app URL and dev server command.
- If the app is not running and the command is unclear, ask before guessing.
- Prefer project harness docs such as `AGENTS.md`, `README.md`, `Makefile`, `package.json`, or `docs/ai/commands.md` for commands.

## Browser Workflow

1. Navigate to the smallest page or flow that reproduces the issue.
2. Observe visible behavior before changing code.
3. Check console errors when UI behavior is broken.
4. Check network failures when data is missing or actions fail.
5. Prefer user-visible assertions over implementation details.
6. After a fix, repeat the same browser flow to verify behavior.

## Avoid

- Do not use browser automation for pure backend logic.
- Do not rely on screenshots alone when a DOM, console, or network signal is clearer.
- Do not enter real secrets, production credentials, or payment details.
- Do not mutate production data.
