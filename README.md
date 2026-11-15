# agentic-coding-resources

Reusable practices, templates, and skill playbooks for coding with AI agents (Claude Code,
Codex, Cursor, and others), distilled from the way the **KAFEE / Kogniv** codebase is
built and reviewed.

The aim is one idea: **make "done" mean the same thing for a human and an agent**, and make
that definition mechanical, cheap to run, and impossible to skip.

## What's here

| Path | What it is |
|---|---|
| [`PRINCIPLES.md`](PRINCIPLES.md) | The principles. Read this first. Stack-neutral, with KAFEE shown as a worked example. |
| [`workflow.md`](workflow.md) | The end-to-end flow: idea → slice → gate → review → PR → deploy, and where each skill fits. |
| [`templates/`](templates/) | Drop-in starter files: `AGENTS.md`, `CLAUDE.md`, `REVIEW.md`, the `check.sh` gate, `.claude/` config. Fill the `<PLACEHOLDERS>`. |
| [`skills/`](skills/) | `SKILL.md` playbooks for the repeatable workflows: gate-driven slices, adversarial review, security audit, memory discipline, condensed plans. |

## How to adopt it in a new repo

1. Copy `templates/` into the repo root and work through every `<PLACEHOLDER>` in
   `templates/AGENTS.md` and `templates/scripts/check.sh`. These two files carry most of
   the value: the agent's standing instructions, and the one command that decides "done".
2. Keep `AGENTS.md` tool-neutral; let `CLAUDE.md` (or your tool's equivalent) import it and
   add tool-specific notes.
3. Wire the skills you want from `skills/` into your agent (as plugin skills, `AGENTS.md`
   references, or copy the playbook text).
4. Set the permission guardrails in `templates/.claude/settings.json`: **ask** before any
   write to shared state (commit, push, PR, merge), **deny** anything that touches
   production.

Nothing here is specific to one language or framework. KAFEE (Python / FastAPI /
multi-tenant / ServiceNow) is used only to make each pattern concrete.
