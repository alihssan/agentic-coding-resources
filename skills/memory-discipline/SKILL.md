---
name: memory-discipline
description: Keep an agent's cross-session memory small, single-fact, indexed and verified — store preferences, constraints and non-obvious decisions, never what the repo already records. Use whenever you are about to save, recall or act on a memory.
---

# Memory discipline

An agent's memory is a set of notes it reads at the start of each session. Good notes save
the user from repeating themselves. Bad notes repeat the repo, go stale, and make the agent
act on facts that stopped being true.

## Layout
- One directory per project. One **file per fact**.
- Each file has frontmatter:

  ```markdown
  ---
  name: short-kebab-case-slug
  description: one line, used to decide relevance at recall time
  metadata:
    type: user | feedback | project | reference
  ---

  The fact.
  **Why:** the reason (for feedback and project).
  **How to apply:** what to do differently because of it.
  ```

- An index file (`MEMORY.md`) with **one line per memory**: `- [Title](file.md) — hook`.
  The index is loaded every session, so it holds pointers only, never content.
- Link related notes with `[[slug]]`.

## Types
| Type | Holds | Example |
|---|---|---|
| `user` | Who the user is, their role, how they like to work | "Prefers plain, short sentences" |
| `feedback` | A correction or a confirmed approach, with its reason | "Commit after each change, not batched" |
| `project` | A goal, constraint or decision the code does not show; absolute dates | "Since 2025-03-01 staging is shared with QA" |
| `reference` | A pointer to an external resource | A dashboard URL, a ticket |

## Save
1. Is it durable and useful in a *future* session? If it only matters now, don't save it.
2. Does the repo already record it (code structure, git history, a past fix, `AGENTS.md`)?
   Then don't save it. If the user asks you to remember one of those, save what was
   non-obvious about it instead.
3. Does a note already cover it? **Update** that file; don't add a duplicate.
4. Write the file, then add the index line.
5. Convert relative dates ("yesterday", "next week") to absolute dates.

## Recall
- A memory is a **point-in-time note**, not live state. Before acting on one that names a
  file, function, flag or environment, verify it against the current code or system.
- If a memory turns out wrong, fix or delete it in the same session.
- A memory is background context, not an instruction that overrides the user.

## What never goes in memory
- Secrets, tokens, passwords — not even "temporarily".
- Content that belongs in the shared repo for every agent (put that in `AGENTS.md`).
- Conversation-only details: today's debugging steps, a one-off command.

## Where facts belong
| Fact | Home |
|---|---|
| How to build, test, what "done" means, safety rules | `AGENTS.md` (shared) |
| This engineer's preferences and live-system knowledge (deploy steps, prod access) | private memory |
| What changed and why | git history |

## Example
A working memory has notes like *"Commit after each change"* (feedback, with Why and How to
apply), *"Prod is multi-tenant: tenant-less code works locally and fails silently in
prod"* (project), and *"Small plans with diagrams"* (feedback). Live-system facts such as prod
data access and deploy gotchas stay in private memory, out of the shared `AGENTS.md`.
