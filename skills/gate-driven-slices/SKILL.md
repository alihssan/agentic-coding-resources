---
name: gate-driven-slices
description: Build a feature as vertical slices, each one made "done" by a single mechanical gate, committed on its own. Use when implementing any non-trivial change with an agent.
---

# Gate-driven slices

The core construction loop: decompose work into the smallest slices that each pass the gate,
and commit after each. The gate — not the agent's judgement — decides "done".

## Preconditions
- A one-command gate exists and is green on the branch point (see `templates/scripts/check.sh`).
- A known-failures baseline exists so the gate reports only *new* failures.

## Loop

1. **Slice.** Break the feature into ordered slices. Each slice is the smallest change that
   (a) does one thing and (b) can pass the gate alone. Write a slice table (see the
   `condensed-plans` skill). The first slice is often a "walking skeleton" that wires the
   ends together with stubs.
2. **Build one slice.** Implement only that slice. For a behaviour change, write or update the
   test first. For a bug fix, write a test that fails first.
3. **Run the gate.** `scripts/check.sh` (or your equivalent). Not green → fix and rerun. Never
   weaken a test, skip it, or add it to the known-failures list to get green.
4. **Commit.** One commit per slice. Message: what changed and why. Exclude `.env` and
   secrets. Push only when asked.
5. **Repeat** until every slice is done, then hand to review.

## Rules
- A slice that cannot be made green is left as an honest WIP with a note, never a fake green.
- Bounded fix attempts per slice (default ~3). If still blocked, stop and report the blocker.
- No drive-by refactors: keep each slice to its task.
- Report faithfully: if the gate could not run (no Docker/network), say so; don't claim a pass.

## Done, per slice
`CHECK: PASS` (exit 0) with the new test(s) passing and no new failures introduced.

## KAFEE example
The redaction feature shipped as ~30 commits: `Add detectors` → `Add engine` → `Wire into the
tool loop (flag off)` → … → one commit per review fix. `scripts/check.sh` gated each. Several
slices surfaced bugs the gate or a follow-up test caught (an empty-vault falsy bug, a prompt-
cache regression) — each fixed in its own commit before moving on.
