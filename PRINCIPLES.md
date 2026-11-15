# Agentic coding principles

Principles for building software with AI agents, so that an agent's work is trustworthy,
reviewable, and safe to ship. Each is stated generally, then grounded in a worked example.

The through-line: an agent is fast and tireless but over-eager. It will declare success,
weaken a test to make it pass, or touch production if you let it. The job of a codebase's
agentic setup is to make the right thing mechanical and the wrong thing hard.

---

## 1. "Done" is a gate, not a claim

An edit is never done. A change is done only when **one command** says so, and that command
fails only on problems *this change* adds.

- The gate runs the cheap mechanical checks: lint on changed files, tests, build.
- It is judged against a **baseline**, not against zero. Real repos have pre-existing lint
  noise and known-failing tests. The gate compares to `origin/main` and reports only *new*
  problems, so it stays green for an unrelated change and red for a real regression.
- Exit 0 = done. There is no "looks right to me."

> **Example:** `scripts/check.sh` runs changed-file `ruff`, unit tests filtered against
> `tests/known_failures.txt` (a few dozen known failures that do not count), and the frontend checks
> only when the frontend changed. `AGENTS.md` says: *"A change is done only when the checks
> pass. An edit alone is never done."* See [`templates/scripts/check.sh`](skills/adopt/templates/scripts/check.sh).

**Anti-pattern:** reporting "all tests pass" after running a subset, or after editing a test
to stop it failing.

## 2. The agent has standing instructions (AGENTS.md)

Put the project's operating manual in one tool-neutral file the agent reads every session:
how to build and test, what "done" means, the architecture that spans files, the
conventions, the **safety boundaries**, and the git rules. Tool-specific files
(`CLAUDE.md`, etc.) import it and add only their own notes.

- Write it for *any* coding agent, not one vendor.
- Keep live-system facts (deploy steps, prod access, incidents) out of it — those belong in
  the engineer's private memory, not in a file the whole team's agents read and act on.

> **Example:** `AGENTS.md` is imported by `CLAUDE.md` via `@AGENTS.md`. It has sections for
> setup/commands, the checks gate, cross-file architecture, conventions, safety, and git.
> See [`templates/AGENTS.md`](skills/adopt/templates/AGENTS.md).

## 3. Work in vertical slices, commit per slice

Decompose a feature into the smallest slices that each pass the gate on their own. Commit
after each one, with a message that says what changed and why. Never batch a dozen changes
into one commit.

- Each commit is a place the review and the gate have both been green.
- A slice that can't be made green is left as an honest WIP, not forced.

> **Example:** a data-redaction feature shipped as ~30 commits — detectors, then the engine,
> then wiring, then one commit per review fix. The standing rule: *"commit after each
> change (not batched)."* See [`skills/gate-driven-slices/SKILL.md`](skills/gate-driven-slices/SKILL.md).

## 4. Tests are evidence, and they are sacred

- A behaviour change starts with a test. A bug fix starts with a test that fails first.
- **Never** weaken, skip, `xfail`, or delete a test to make the gate pass, and never add a
  line to the known-failures baseline to hide a regression.
- Prove a claim by running it. "This breaks" is backed by failing output; "this is fixed" is
  backed by the gate.

> **Example:** `AGENTS.md`: *"Never skip, delete, xfail or weaken a test to make it pass.
> Never add a line to tests/known_failures.txt to hide a regression."*

## 5. Fail closed, especially at trust boundaries

When an agent writes code that sits on a security or data boundary, the default on any error
or uncertainty must be to **block**, not to pass the data through. Make the safe path the one
that happens when something goes wrong.

> **Example:** a redaction layer turns any unexpected exception into a "blocked" error in
> enforce mode, so a bug stops the data instead of leaking it; a flag-off deployment is inert
> and never reads the policy file. This principle was itself the subject of a review fix.

## 6. Never touch production (make it impossible, not just discouraged)

Agents must not apply infra, deploy, run destructive cloud commands, or write to production
data. Enforce it with permission rules, not willpower: **deny** the dangerous commands in
config so the agent can't run them even if it decides to.

> **Example:** `.claude/settings.json` denies `terraform apply/destroy`, `make deploy/image/
> migrate`, and `az … create/delete/secret set`. `AGENTS.md` § Safety says there is no
> staging; production is real customer infrastructure. See
> [`templates/.claude/settings.json`](skills/adopt/templates/.claude/settings.json).

## 7. Confirm before outward or irreversible actions

Commit, push, PR, merge, sending anything to an external service — ask first unless durably
authorized. Approval in one context does not carry to the next. Publishing is not reversible
just because you can delete afterwards.

> **Example:** `.claude/settings.json` lists `git commit/push`, `gh pr create/merge`, and
> write API calls under `ask`. The agent proposes; the human approves each outward step.

## 8. Review adversarially before merge

Before a PR, run a structured review that actively tries to break the change — ideally with
more than one model, and an Optimizer (find everything) vs Skeptic (refute it, catch false
positives) split. Report findings with a file, a line, and a concrete trigger; back
"this breaks" with command output; separate confidence from severity.

> **Example:** the `adversarial-review` plugin runs Optimizer + Skeptic across Sonnet and Opus,
> gated by an escalation score, review-only by default. `REVIEW.md` holds the house rules and
> `.claude/docs/code-review.md` the severity lenses. See
> [`skills/adversarial-review/SKILL.md`](skills/adversarial-review/SKILL.md).

## 9. Security is a separate, evidence-first pass

For a feature on a real trust boundary, run a dedicated security audit, not just a code
review. Require every finding to name a lower-trust principal, the crossed boundary, and a
concrete result. A candidate without a demonstrated boundary violation is `needs_validation`,
not a vulnerability — and it gets no severity. Run it **source-only** when you can't provide
a real sandbox, and say so.

> **Example:** a six-phase source-only audit of a data-redaction feature produced 5
> `needs_validation` leads (0 confirmed, because nothing could be safely executed), written
> up as a GitHub issue. See [`skills/security-audit/SKILL.md`](skills/security-audit/SKILL.md).

## 10. Plans are small, visual, and incremental

Before a feature, do the engineering thinking — problem, requirements, testable acceptance
criteria, the smallest safe design, risks, vertical slices — then write only the result on one
page. Start with an easy flowchart of what the feature does for the user. Write in
Simplified Technical English: short sentences, active voice, easy words. Detail only the next
slice, and revise the plan as exploration changes the picture.

> **Example:** a standing team preference — *"targeted and small plans … condensed … make
> graphical representations of workflow."* See
> [`skills/condensed-plans/SKILL.md`](skills/condensed-plans/SKILL.md).

## 11. Memory is curated, not hoarded

Keep durable facts the agent needs across sessions — preferences, project constraints,
non-obvious decisions, external pointers — as small, single-fact notes with an index. Don't
store what the repo already records (code structure, git history, past fixes). Verify a
memory against current code before acting on it; it is a point-in-time note, not live state.

> **Example:** each memory is one file with frontmatter and a one-line pointer in `MEMORY.md`;
> feedback memories carry a *Why* and a *How to apply*. See
> [`skills/memory-discipline/SKILL.md`](skills/memory-discipline/SKILL.md).

## 12. Report outcomes faithfully

State plainly when tests fail, when a step was skipped, and when a check could not run (no
Docker, no network) — never report a pass you didn't get. When something is verified, say so
without hedging. Distinguish what you observed from what you assume. Correct your own earlier
mistakes out loud.

> **Example:** when the security sandbox was unavailable, the audit recorded `needs_validation`
> with the exact missing capability rather than claiming a clean result; a flaky-looking test
> was investigated and fixed, not explained away.

## 13. Right-size the effort to the risk

Cheap mechanical checks first (they're free). Escalate to multi-model review and deep audits
only where the change warrants it. A docs-only change does not need the same ceremony as an
auth or crypto change. Make the escalation rule explicit and mechanical, not a vibe.

> **Example:** the review plugin scores a change (auth +3, crypto +3, >20 files +2, …) and
> picks skip / standard / full depth from the score.

---

### The shortest version

Define *done* as a gate. Give the agent standing instructions. Slice the work and commit
each slice. Never weaken a test. Fail closed. Keep the agent out of production. Ask before
anything outward. Review adversarially, audit security separately, and report honestly.
