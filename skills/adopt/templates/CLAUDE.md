# CLAUDE.md

Guidance for Claude Code in this repository. The shared, tool-neutral instructions
(commands, checks, architecture, conventions, safety, git) live in `AGENTS.md` and are
imported here:

@AGENTS.md

## Commands and checks (repeated for tools that read only CLAUDE.md)

```bash
<THE GATE — one command>                 # the definition of done
<lint command>
<typecheck command>
<test command>
```

## Claude Code notes

- **Review before a PR.** Run `<your review command, e.g. /adversarial-review:run --no-fix>`
  (review-only by default). House rules are in `REVIEW.md` and the severity lenses in
  `.claude/docs/code-review.md`.
- **Permissions.** `.claude/settings.json` asks before `git commit`, `git push` and PR
  merges, and denies the production commands listed in `AGENTS.md` § Safety. Do not work
  around a denial; ask instead.
- **Memory.** Facts about the live system (deploy steps, prod access, incidents) belong in
  your private memory, not in `AGENTS.md`.
