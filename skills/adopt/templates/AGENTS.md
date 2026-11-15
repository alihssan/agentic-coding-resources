# AGENTS.md

Instructions for any coding agent working in this repository (Claude Code, Codex, Cursor and
others). A tool-specific file (e.g. `CLAUDE.md`) imports this and adds only its own notes.

> This is a template. Replace every `<PLACEHOLDER>`. Delete the guidance in quote blocks once
> you've filled the section. Keep it tool-neutral: write for *any* agent.

`<ONE-PARAGRAPH DESCRIPTION OF THE SYSTEM: what it is, who uses it, the one or two
cross-cutting properties an agent must never break — e.g. tenancy model, auth model.>`

Stack: `<languages, frameworks, datastores, infra>`.

## 1. Setup and commands

Run everything from `<the repo root / the relevant sub-project>`.

```bash
<how to create the environment>
<how to install dependencies — and which lockfile must NOT be rewritten, if any>
<how to run the app locally>
<how to run background workers / services, if any>
```

> List the smoke scripts or manual steps that exercise end-to-end paths, if you have them.

## 2. Checks: what "done" means

A change is done only when the checks pass. **An edit alone is never done.**

```bash
<THE GATE — one command, e.g. scripts/check.sh>   # exit 0 = done
```

It runs, and fails only on problems your change adds:

| Check | Command | Baseline on main |
|---|---|---|
| Lint, changed files | `<lint command on changed files>` | `<is the repo-wide baseline clean? if not, say so>` |
| Tests | `<test command>` | `<known-failing tests, if any, and where they are listed>` |
| Build / typecheck | `<build or typecheck command>` | `<baseline>` |

Rules:
- Write or update the test first for a behaviour change. A bug fix starts with a failing test.
- Never skip, delete, `xfail` or weaken a test to make it pass.
- Never add a line to the known-failures list to hide a regression. Delete a line when you
  genuinely fix that failure.
- **A review finding is fixed when its inputs are tests.** Put the reviewer's exact inputs
  in tests that fail first. A green gate says nothing about a case no test holds.
- Measure a fix with numbers, before and after ("215 of 300 rows blocked", then "0").
- A test you added on this branch, not yet merged, may change when a later fix on the same
  branch changes the intended behaviour. Say why in the commit. A merged test is never
  weakened.
- If a check cannot run (no Docker, no network), say so plainly. Do not report a pass.

## 3. Architecture (the parts that span files)

> Document only what an agent can't infer from one file: the invariants, the single sources
> of truth, the layers that must stay separate. For each, say where it lives and the rule.

- **`<invariant, e.g. tenant isolation>`:** `<the rule, and the files/pattern that enforce it>`.
- **`<single source of truth, e.g. the agent/prompt catalog>`:** `<what lives there, what must
  not be edited elsewhere>`.
- **`<a layer that must stay neutral/separate>`:** `<the boundary rule>`.
- **`<a boundary every path must cross, e.g. redaction or an auth check>`:** list every
  entry point that must call it (`<each dispatcher, handler, worker>`). A second entry
  point that skips it is the usual bug, and each copy of the call needs a test.

## 4. Conventions

- **Errors:** `<where domain errors are raised vs mapped to the transport layer>`.
- **Config:** read from `<the one typed settings object>`, never from the raw environment.
- **Secrets:** `<how secrets are stored; never in plain text>`.
- **New persistent state / migrations:** `<the required pattern; migrations need a working
  downgrade()>`.
- **Clients / external systems:** `<the one place they are constructed>`.
- **Prompts (if the system calls a model):** shared rules live in `<one place>`, not copied
  into each prompt. A "write it like this" example in a prompt must follow the prompt's
  own rules: a model copies examples more than it follows rules.
- **Detectors and filters (if the system scans text):** to remove a false positive, drop
  the finding. Never rewrite the text the other rules read: that hides what they need to
  see, and it can hide a real hit.
- **Scope:** keep each change to its task. No drive-by refactors.

## 5. Safety boundaries

`<State plainly whether there is a staging environment. If production is real, say so.>`

- **Never touch production.** Do not run: `<the exact deploy / infra / destructive commands>`.
  If a task needs one, stop and ask the maintainer. (These should also be **denied** in the
  agent's permission config — see `.claude/settings.json`.)
- **Infra:** plan only, from the main branch. A person applies.
- **Secrets:** never put a secret value in code, tests, fixtures, config or commit messages.
  Treat any local `.env` as sensitive: never print or copy it.
- **Data:** do not read, print or summarise customer data files unless the task needs them.

## 6. Git and pull requests

- **Branch:** work on a feature branch from `<default branch>`. Never commit to it directly.
- **Ask before** every `git commit`, `git push`, PR creation and merge. A yes covers that
  one action. It does not cover the next branch or the next PR.
- **Commits:** one per logical change. The message says what changed and why.
- **Before opening a PR:** the gate passes, and the review (see `REVIEW.md`) is run with its
  critical and major findings fixed or answered.
- **PR body:** what changed, why, and how it was verified (commands and results).
