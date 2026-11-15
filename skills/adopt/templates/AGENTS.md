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
- If a check cannot run (no Docker, no network), say so plainly. Do not report a pass.

## 3. Architecture (the parts that span files)

> Document only what an agent can't infer from one file: the invariants, the single sources
> of truth, the layers that must stay separate. For each, say where it lives and the rule.

- **`<invariant, e.g. tenant isolation>`:** `<the rule, and the files/pattern that enforce it>`.
- **`<single source of truth, e.g. the agent/prompt catalog>`:** `<what lives there, what must
  not be edited elsewhere>`.
- **`<a layer that must stay neutral/separate>`:** `<the boundary rule>`.

## 4. Conventions

- **Errors:** `<where domain errors are raised vs mapped to the transport layer>`.
- **Config:** read from `<the one typed settings object>`, never from the raw environment.
- **Secrets:** `<how secrets are stored; never in plain text>`.
- **New persistent state / migrations:** `<the required pattern; migrations need a working
  downgrade()>`.
- **Clients / external systems:** `<the one place they are constructed>`.
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
- **Ask before** every `git commit`, `git push`, PR creation and merge.
- **Commits:** one per logical change. The message says what changed and why.
- **Before opening a PR:** the gate passes, and the review (see `REVIEW.md`) is run with its
  critical and major findings fixed or answered.
- **PR body:** what changed, why, and how it was verified (commands and results).
