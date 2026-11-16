---
name: adopt
description: Set up agentic coding in the current repo, legacy or new — copy in the bundled templates (AGENTS.md, CLAUDE.md, REVIEW.md, a check.sh "done" gate, .claude permission guardrails) without overwriting anything, detect the stack, fill every placeholder, merge existing agent files, record pre-existing test failures, and prove the gate goes green and red. Use once per repo when the user asks to adopt, set up or add the agentic coding setup, gate, AGENTS.md or guardrails.
---

# Adopt

This skill brings its own templates (`templates/` next to this file) and a script that copies
them in without overwriting anything. Then it makes them true for **this** repo. The result is one reviewed commit that adds a working gate, standing
instructions and permission guardrails.

## Rules
- Work on a new branch (`agentic-setup`). Never on the default branch.
- **Detect before you ask.** Read the repo first. Ask the user only for what the code cannot
  tell you (is there staging? which invariants matter most?). Ask those in **one** batch.
- Do not change application code or existing tests. This skill adds tooling only.
- Do not run deploy, infra or migration commands to "see what they do". Read them.
- Ask before the commit. Never push without being asked.

## Steps

### 1. Copy the templates in
Make sure the working tree is clean and you are on a new branch (`git checkout -b
agentic-setup`). Then run the script that sits in this skill's directory:

```bash
bash <this skill's directory>/scripts/install.sh --dry-run .   # show the plan to the user
bash <this skill's directory>/scripts/install.sh .
```

It adds `AGENTS.md`, `CLAUDE.md`, `REVIEW.md`, `scripts/check.sh`, `tests/known_failures.txt`,
`.claude/` config and the day-to-day skills. If any tracked `*.tf` file uses the
`hashicorp/aws` provider, it also copies the `aws-terraform` skill: then follow that skill's
"Setting up a repo" section after step 7. A file that already exists is never touched: the
template goes to `.agentic/incoming/` instead (merged in step 4). It also saves the exact
placeholder list to `.agentic/placeholders.txt` (checked in step 7).

### 2. Detect (read only)
Find, and note the file each answer came from:

| What | Where to look |
|---|---|
| Languages, package manager, lockfile | `package.json`, `pyproject.toml`, `requirements*.txt`, `go.mod`, `pom.xml`, `build.gradle*`, `Cargo.toml`, `Gemfile`, `*.csproj` |
| Lint / format / typecheck commands | the same files' scripts and tool sections, `Makefile`, `.pre-commit-config.yaml` |
| Test command and runner | scripts, `Makefile`, CI config (`.github/workflows/`, `.gitlab-ci.yml`, `azure-pipelines.yml`, `Jenkinsfile`) |
| Build command | the same |
| Default branch | `git symbolic-ref refs/remotes/origin/HEAD` (else `main` / `master`) |
| Deploy, infra, migration, cloud commands | `Makefile`, CI deploy jobs, `terraform/`, `Dockerfile`, `helm/`, scripts named `deploy*`, `release*`, `migrate*` |
| Existing agent files | `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `.github/copilot-instructions.md`, `.claude/settings.json` |
| Secrets files | `.env*`, `*.pem`, `secrets*` — note they exist, never open them |

CI config is the best single source: what CI runs is what the team already trusts.

### 3. Ask once
Show what you detected in a short table, then ask only the gaps, for example:
- Is there a staging environment, or is anything not local real production?
- What are the 1–3 things an agent must never break (tenant isolation, auth model, a
  public API contract, money handling)?
- Anything to add to the deny list (commands that touch production)?

### 4. Merge staged files (legacy repos)
For each file in `.agentic/incoming/`, merge it into the existing file at the same path.
**The existing content wins** — the template adds only what is missing.
- `CLAUDE.md` exists → keep it, add `@AGENTS.md` near the top, drop sections that now
  duplicate `AGENTS.md`.
- `AGENTS.md` exists → add the missing sections (checks gate, safety, git) from the template.
- `.claude/settings.json` exists → union the `permissions.ask` and `permissions.deny` lists.
  Keep every existing key. Keep `allow` entries unless one allows a denied command — flag that.
- Any other conflict → show the diff and ask.

Delete each `.agentic/incoming/` file once merged. Keep `.agentic/placeholders.txt` until
step 7.

### 5. Fill the placeholders
- **`AGENTS.md`**: the system paragraph, commands, check table, architecture invariants (from
  the user's answers plus what the code shows), conventions you can see in the code, safety
  section with the real deny commands, git section with the real default branch. Delete the
  template's quote-block guidance.
- **`CLAUDE.md`**: the commands block and the review command.
- **`scripts/check.sh`**: the glob, lint command, test command, failed-id extraction, build
  scope and build command. Use the stack table below. Keep the structure.
- **`.claude/settings.json`**: replace placeholder deny entries with the real commands found in
  step 2. Remove placeholder lines that do not apply. Never leave a `<…>` entry.
- **`REVIEW.md`** and **`.claude/docs/code-review.md`**: fill the top lenses from the
  invariants. If one is unknown, write `TODO(owner): …`, not a guess.

#### Stack snippets for `check.sh`
| Stack | `<GLOB>` | Lint | Test → failed ids |
|---|---|---|---|
| Python / pytest | `'*.py'` | `ruff check` | `pytest -q -rf` → `grep '^FAILED ' "$tmp/test.txt" \| awk '{print $2}'` |
| JS/TS / Jest | `'*.js' '*.ts' '*.tsx'` | `npx eslint` | `npx jest --ci` → `grep -E '^\s+● ' "$tmp/test.txt" \| sed 's/^ *● //'` (or `--json` + `jq`) |
| JS/TS / Vitest | `'*.ts' '*.tsx'` | `npx eslint` | `npx vitest run --reporter=json --outputFile="$tmp/v.json"` → `jq -r '.testResults[].assertionResults[] \| select(.status=="failed") \| .fullName' "$tmp/v.json"` |
| Go | `'*.go'` | `gofmt -l` (+ `go vet ./...` as build) | `go test ./... -json` → `jq -r 'select(.Action=="fail" and .Test) \| .Package+"/"+.Test'` |
| Java / Maven | `'*.java'` | `mvn -q spotless:check` or `checkstyle:check` | `mvn -q test` → parse `target/surefire-reports/*.txt` for `FAILURE` |

If the repo has **no tests yet** (new project): use a test command that passes on zero tests
(e.g. `pytest -q || [ $? -eq 5 ]`), and leave `known_failures.txt` empty.

### 6. Record the baseline (legacy repos)
On a clean checkout of the default branch, run the test command once. Put every failing test
id in `tests/known_failures.txt`, one per line, with one header comment:
`# baseline captured <YYYY-MM-DD> from <default branch> @ <short sha>`.
Lint needs no baseline: the gate lints changed files only. If the suite cannot run here (no
DB, no Docker), say so, and ask whether to gate only on the tests that can run.

### 7. Prove the gate
1. `scripts/check.sh` on the branch → must print `CHECK: PASS`.
2. Add a throwaway failing test (e.g. `assert False`) in the test directory → run the gate →
   must print `CHECK: FAIL` naming that test. Delete the test.
3. No placeholders left — this must print nothing (step 1 saved the exact list):
   ```bash
   grep -rnF -f .agentic/placeholders.txt AGENTS.md CLAUDE.md REVIEW.md scripts/check.sh \
     tests/known_failures.txt .claude/settings.json .claude/docs/
   ```
4. `jq . .claude/settings.json` → valid JSON.

If any step fails, fix it. If it cannot be fixed, report it plainly. Never report a pass you
did not get. When all four pass, delete `.agentic/` and the `/.agentic/` lines step 1
added to `.gitignore`.

### 8. Commit (after asking)
One commit on `agentic-setup`: `Add agentic coding setup (gate, AGENTS.md, guardrails)`. The
body lists the detected commands, the baseline size, and any `TODO(owner)` left. Then tell the
user how to use it day to day: plan with `condensed-plans`, build with `gate-driven-slices`,
and review with `adversarial-review` before a PR.

## Done
The gate is green on the branch, red on a planted failure, and no placeholder is left. One
commit is waiting for the user's approval.
