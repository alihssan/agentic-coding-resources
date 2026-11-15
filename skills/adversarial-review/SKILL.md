---
name: adversarial-review
description: Review a finished branch by trying to break it — mechanical checks first, then an Optimizer (find everything) and a Skeptic (refute false positives), scaled to the risk of the change. Use before opening a PR.
---

# Adversarial review

A review that assumes the change is wrong and tries to prove it. Two roles pull in opposite
directions so that the final list is both complete and true.

## Preconditions
- The feature is developer-done: every slice is committed and the gate is green.
- `REVIEW.md` (house rules) and `.claude/docs/code-review.md` (severity lenses) exist. See
  `templates/`.
- Default mode is **review-only**: report findings, do not modify code
  (`templates/.claude/adversarial-review.json` → `"mode": "no-fix"`).

## Loop

1. **Mechanical checks.** Run the gate and any extra analysis listed in `REVIEW.md`. They are
   free and they settle facts before any opinion. A new failure is already a finding.
2. **Score the change.** Pick the depth from an explicit score, not a feeling. Example:

   | Signal | Points |
   |---|---|
   | Touches auth / access control | +3 |
   | Touches crypto or secrets handling | +3 |
   | Touches a Critical lens in `code-review.md` | +3 |
   | More than 20 files changed | +2 |
   | New migration / persistent-state change | +2 |
   | Docs or tests only | −3 |

   Low score → skip or one quick pass. Medium → standard (one Optimizer, one Skeptic).
   High → full (both roles on more than one model).
3. **Optimizer.** Read the diff against the lenses and list every plausible defect. Bias to
   recall. Each candidate: file, line, what fails, and a concrete input or state that
   triggers it.
4. **Skeptic.** Take each candidate and try to refute it: read the surrounding code, run a
   test, check the baseline. Bias to precision. Output per candidate: `confirmed`,
   `refuted` (with the reason), or `plausible` (could not decide either way).
5. **Cross-model (full depth).** Run the roles on a second model (and optionally a second
   vendor). A finding that two independent reviewers reach is stronger evidence. A finding
   only one reached gets the Skeptic's verdict, not a vote.
6. **Report.** Rank by severity (Critical → Major → Minor), state confidence separately, and
   mark pre-existing problems as pre-existing.
7. **Fix (only if asked).** Fix confirmed Critical/Major findings as their own slices, each
   through the gate and committed alone (see `gate-driven-slices`). Then re-run the review on
   the fix commits to check the fix did not add a new defect.

## Rules
- A "this breaks" claim is backed by output: a failing test, a lint or type line, a trace.
- Severity and confidence are two fields. A likely-but-unproven Critical stays Critical and is
  marked `plausible`; it is not quietly downgraded.
- A disputed finding is recorded with both sides, not dropped.
- Do not re-review what the linter owns (formatting, import order).
- Do not block a PR on the known-failures baseline or other pre-existing problems.

## Done
Every candidate has a verdict. Confirmed Critical findings are fixed or the PR is blocked.
Confirmed Major findings are fixed or carry a written reason in the PR.

## KAFEE example
KAFEE runs the `adversarial-review` plugin: Optimizer + Skeptic across Sonnet and Opus, depth
picked from an escalation score (auth +3, crypto +3, >20 files +2, …), review-only by default.
On the redaction feature the review findings each became their own fix commit, including the
change that made the redaction layer fail closed (an unexpected exception becomes
`RedactionBlocked` in enforce mode instead of passing data through).
