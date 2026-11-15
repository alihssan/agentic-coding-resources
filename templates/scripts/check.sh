#!/usr/bin/env bash
# The "done" gate for a change. Fails only on problems the change ADDS, judged against BASE:
#   - lint on the files changed vs BASE (the repo-wide baseline may not be clean)
#   - tests: any failure not listed in the known-failures baseline
#   - build / typecheck, when the relevant files changed
# Usage: scripts/check.sh            # compare against origin/main
#        BASE=main scripts/check.sh
#
# TEMPLATE: replace the <PLACEHOLDER> commands for your stack. The structure — changed-file
# scope, a known-failures baseline, new-failures-only — is the point; keep it.
set -uo pipefail

cd "$(git rev-parse --show-toplevel)"
BASE="${BASE:-origin/main}"
fail=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Files changed on the branch, uncommitted, and new untracked — all three.
changed() {
  git diff --name-only --diff-filter=ACMR "$BASE"...HEAD -- "$@"
  git diff --name-only --diff-filter=ACMR HEAD -- "$@"
  git ls-files --others --exclude-standard -- "$@"
}

# 1. Lint, changed source files only.
#    <GLOB> = your source extension(s), e.g. '*.py' or '*.ts' '*.tsx'
changed '<GLOB>' | sort -u | while read -r f; do [ -f "$f" ] && echo "$f"; done >"$tmp/src.txt"
n="$(grep -c . "$tmp/src.txt" || true)"
if [ "$n" -gt 0 ]; then
  if tr '\n' '\0' <"$tmp/src.txt" | xargs -0 <LINT_COMMAND> >"$tmp/lint.txt" 2>&1; then
    echo "lint:  ok ($n changed files)"
  else
    echo "lint:  FAIL on changed files"; cat "$tmp/lint.txt"; fail=1
  fi
else
  echo "lint:  skip (no changed source files)"
fi

# 2. Tests, NEW failures only (compared to a committed known-failures baseline).
#    Replace <TEST_COMMAND> and the way failing test ids are extracted for your runner.
<TEST_COMMAND> >"$tmp/test.txt" 2>&1
<EXTRACT_FAILED_TEST_IDS from $tmp/test.txt> | sort -u >"$tmp/failed.txt"
grep -v '^#' tests/known_failures.txt 2>/dev/null | sed '/^$/d' | sort -u >"$tmp/known.txt"
new="$(comm -23 "$tmp/failed.txt" "$tmp/known.txt")"
if [ -n "$new" ]; then
  echo "tests: FAIL, new failures:"; echo "$new" | sed 's/^/  /'; fail=1
else
  echo "tests: ok"
fi

# 3. Build / typecheck, only when the relevant files changed.
if [ -n "$(changed '<BUILD_SCOPE_GLOB>' || true)" ]; then
  if <BUILD_OR_TYPECHECK_COMMAND> >"$tmp/build.txt" 2>&1; then
    echo "build: ok"
  else
    echo "build: FAIL"; tail -30 "$tmp/build.txt"; fail=1
  fi
else
  echo "build: skip (unchanged)"
fi

[ "$fail" = 0 ] && echo "CHECK: PASS" || echo "CHECK: FAIL"
exit "$fail"
