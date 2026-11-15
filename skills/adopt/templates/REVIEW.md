# REVIEW.md

House rules for code review in this repo, for human reviewers and review agents. Severity
lenses with examples are in `.claude/docs/code-review.md`. Background is in `AGENTS.md`.

> Template. Replace the `<PLACEHOLDER>` items with your project's real risks and conventions,
> ordered most-dangerous first.

## Mechanical checks (run these first, they are free)

```bash
<THE GATE — scripts/check.sh>
<any extra analysis, e.g. typecheck, run only on changed files>
```

- Run the fast tests. Heavier suites (integration, e2e) run only if their environment is up;
  say if it was not.
- Judge against the **baseline**: the repo may have pre-existing lint noise and known-failing
  tests. Report those only as pre-existing, at most once. A *new* failure is a finding.
- Never let a review rewrite the lockfile.

## What to flag (most important first)

1. **`<top invariant, e.g. tenant/data isolation>`:** `<the specific things that break it>`.
2. **`<auth / access control>`:** `<what every new entry point needs>`.
3. **`<production-mode behaviour>`:** `<code that works only in a dev config and fails in prod>`.
4. **Secrets and production:** any secret value in code/tests/config/logs; anything that runs
   against production resources.
5. **Correctness:** `<your common footguns — concurrency, resource pools, missing awaits,
   transaction scope>`.
6. **Conventions:** `<errors mapped at the edge, config from the settings object, clients
   built in one place, …>`.
7. **Migrations / persistent state:** no working rollback, a destructive change without a data
   plan, an edited already-shipped migration.
8. **Tests:** a behaviour change without a test; a bug fix without a test that failed first; a
   test skipped, `xfail`-ed or weakened, or a line added to the known-failures list.

## What to skip
- Formatting and import order (the linter owns them).
- The known-failing tests and the repo-wide lint/type baselines — flag only what the change adds.
- Generated files and the lockfile (unless the change edits it without a dependency change).
- Customer data files — do not open them.
- Style preferences with no correctness or maintenance cost.

## How to report
- Each finding: a file and line, what fails, and a concrete input or state that triggers it.
- Back a "this breaks" claim with command output (a failing test, a lint/type line).
- Mark pre-existing problems as pre-existing. Do not block a PR on them.
