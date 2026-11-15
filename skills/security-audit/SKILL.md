---
name: security-audit
description: Evidence-first security audit for a feature on a real trust boundary (auth, tenant isolation, crypto, data leaving the system). Every finding names a principal, a crossed boundary and a concrete result; unproven candidates are needs_validation with no severity. Use after the adversarial review, before the PR.
---

# Security audit

A code review asks "is this correct?". A security audit asks "can a less-trusted party make
this do something it must not?". It is a separate pass, with stricter rules of evidence.

## When to run it
Run it when the change sits on a trust boundary: authentication or authorization, tenant or
data isolation, cryptography or secrets, input from an external system, or data leaving the
system (logs, model prompts, third-party APIs). Skip it for changes that cross no boundary,
and say that you skipped it.

## Phases

1. **Scope.** Name the feature, the files, and the execution mode: **sandboxed** (you can run
   exploits against a disposable copy) or **source-only** (you can only read code). Never
   execute anything against production or shared environments. If no safe sandbox exists,
   choose source-only and say so in the report.
2. **Threat model.** List the principals (anonymous user, user of tenant A, tenant admin,
   external system, the model itself) and the boundaries between them. Note what each
   boundary protects.
3. **Map entry points.** Every way data or control enters the feature: routes, webhooks,
   queue messages, scheduled jobs, model tool calls, config files.
4. **Hunt.** For each entry point × boundary, look for the crossing: missing auth check,
   identity taken from a client-controlled value, query without the tenant filter, error path
   that skips the guard, secret written to a log, data sent out before redaction.
5. **Validate.** For each candidate, try to demonstrate it. In sandboxed mode, run it and
   capture the output. In source-only mode, trace the exact path line by line and state what
   would have to be true at runtime.
6. **Report.** Classify and write up (below). Hand confirmed findings to the gate-driven-slices
   loop as fixes. Put the report where the team tracks work (an issue, not only the chat).

## Finding format
Every finding has:
- **Principal** — who, with what access, starts the attack.
- **Boundary** — which protection is crossed.
- **Path** — file:line steps from entry point to effect.
- **Result** — the concrete thing that happens (reads tenant B's rows, logs the token, …).
- **Evidence** — the command output, or the line-by-line trace in source-only mode.
- **Status** — `confirmed` (demonstrated) or `needs_validation` (not demonstrated).
- **Severity** — only for `confirmed`. A `needs_validation` lead has **no severity**.
- For `needs_validation`: what capability is missing to confirm it, and the exact test that
  would settle it.

## Rules
- No boundary crossing, no finding. "This looks risky" is a note, not a vulnerability.
- Do not inflate: zero confirmed findings is a valid result, stated plainly.
- Do not deflate: a lead you could not test stays open as `needs_validation`; it is not
  reported as "clean".
- Fail-closed behaviour is checked explicitly: what happens on an exception, a timeout, a
  missing config value?

## Done
Every entry point × boundary pair was looked at, every candidate has a status, and the report
states the execution mode and what could not be checked.

## Example
A data-redaction feature (data leaving the system to a model) had a six-phase source-only audit,
because nothing could be safely executed against a real environment. Result: 5
`needs_validation` leads, 0 confirmed, each with the missing capability and the test that
would settle it, filed as one GitHub issue.
