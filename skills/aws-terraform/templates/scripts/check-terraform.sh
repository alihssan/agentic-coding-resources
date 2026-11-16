#!/usr/bin/env bash
# The infra gate for AWS Terraform. For every Terraform directory a change touches, it runs:
#   fmt -check · init -backend=false · validate · sensitive (rule S10) · tflint (aws ruleset)
#   · trivy config · terraform test on tests/unit.tftest.hcl (mocked, no AWS credentials)
# It never touches a backend, never plans against AWS and never applies.
#
# Usage: scripts/check-terraform.sh                 # dirs changed vs origin/main
#        BASE=main scripts/check-terraform.sh
#        ALL=1 scripts/check-terraform.sh           # every Terraform dir in the repo
#        scripts/check-terraform.sh infra/network   # just these dirs
#        SKIP=trivy scripts/check-terraform.sh      # skip named steps (comma list); printed as SKIP
#
# A missing tool is a FAIL, not a silent pass. Install it, or SKIP it on purpose.
set -uo pipefail

root="$(git rev-parse --show-toplevel)"
cd "$root"
BASE="${BASE:-origin/main}"
SKIP=",${SKIP:-},"
TRIVY_SEVERITY="${TRIVY_SEVERITY:-HIGH,CRITICAL}"
fail=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

skipped() { case "$SKIP" in *",$1,"*) return 0 ;; esac; return 1; }
need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "  $2: FAIL ($1 not installed; install it or set SKIP=$2)"; return 1
  fi
}

# Rule S10, mechanically. Prints one line per problem; exit 1 if any.
#  - a variable or output whose name says "secret" must have `sensitive = true`
#  - a helm_release must not pass a secret-named chart value in `set` / `set_list`
#    (use `set_wo` or `set_sensitive`)
# A block that is not a secret despite its name opts out with a comment inside it:
#   # not-secret: <reason>
# Terraform itself already rejects a non-sensitive output that refers to a sensitive value.
check_sensitive() {
  awk '
    function secret(n) {
      n = tolower(n)
      if (n ~ /^(manage|enable|create|use|is|has)_/) return 0
      if (n ~ /_(arn|arns|id|ids|name|names|version|revision|length|path|paths|days|seconds|minutes|hours|ttl|count|enabled|policy|rotation|rotation_days)$/) return 0
      if (n ~ /_wo$/) return 1
      return n ~ /(^|_)(password|passwd|secret|secrets|token|tokens|api_key|access_key|secret_key|private_key|credential|credentials|connection_string|client_secret|auth_key|signing_key)(_|$)/
    }
    FNR == 1 { kind = "" }
    kind == "" && match($0, /^(variable|output) "[^"]+"/) {
      kind = substr($0, 1, index($0, " ") - 1)
      name = $0; sub(/^[a-z]+ "/, "", name); sub(/".*/, "", name)
      start = FNR; sens = 0; optout = 0
      next
    }
    kind != "" && kind != "helm" {
      if ($0 ~ /^[ \t]*sensitive[ \t]*=[ \t]*true/) sens = 1
      if ($0 ~ /#[ \t]*not-secret:/) optout = 1
      if ($0 ~ /^}/) {
        if (secret(name) && !sens && !optout)
          printf "%s:%d: %s \"%s\" looks secret: add sensitive = true (or # not-secret: <reason>)\n", FILENAME, start, kind, name
        kind = ""
      }
      next
    }
    kind == "" && /^resource "helm_release" "/ { kind = "helm"; list = ""; next }
    kind == "helm" {
      if ($0 ~ /^}/) { kind = ""; next }
      if (match($0, /^[ \t]*(set|set_list|set_sensitive|set_wo)[ \t]*(=[ \t]*\[|\{)/)) {
        list = $0; sub(/^[ \t]*/, "", list); sub(/[ \t=\{\[].*/, "", list)
      }
      if (list ~ /^(set|set_list)$/ && match($0, /name[ \t]*=[ \t]*"[^"]+"/)) {
        v = substr($0, RSTART, RLENGTH); sub(/^name[ \t]*=[ \t]*"/, "", v); sub(/"$/, "", v)
        k = v; gsub(/[^A-Za-z0-9]+/, "_", k)
        # camelCase chart keys (adminPassword) are caught by the tolower() test below.
        if (secret(k) || tolower(v) ~ /(password|secret|token|apikey|privatekey)/)
          printf "%s:%d: helm_release chart value \"%s\" in %s: use set_wo or set_sensitive\n", FILENAME, FNR, v, list
      }
    }
  ' "$@"
}

# A Terraform dir = a dir that holds *.tf files. A changed test or tfvars file counts for
# the module above it. Hidden dirs (.terraform, .git) are never module dirs.
tf_dir_of() {
  local d
  d="$(dirname "$1")"
  case "$d" in */tests | tests) d="$(dirname "$d")" ;; esac
  case "$d" in */envs/* | envs/*) d="${d%%/envs/*}"; [ "$d" = "envs" ] && d="." ;; esac
  echo "$d"
}

if [ "$#" -gt 0 ]; then
  printf '%s\n' "$@" >"$tmp/dirs"
elif [ "${ALL:-0}" = 1 ]; then
  git ls-files --cached --others --exclude-standard -- '*.tf' \
    | while read -r f; do dirname "$f"; done | sort -u >"$tmp/dirs"
else
  {
    git diff --name-only --diff-filter=ACMRD "$BASE"...HEAD -- '*.tf' '*.tftest.hcl' '*.tfvars' '*.tf.json'
    git diff --name-only --diff-filter=ACMRD HEAD -- '*.tf' '*.tftest.hcl' '*.tfvars' '*.tf.json'
    git ls-files --others --exclude-standard -- '*.tf' '*.tftest.hcl' '*.tfvars'
  } | while read -r f; do tf_dir_of "$f"; done | sort -u >"$tmp/dirs"
fi

# Found dirs under a hidden dir (.claude/skills/aws-terraform/example, .github, ...) are
# tool files, not this repo's infra. Dirs passed as arguments are always checked.
if [ "$#" -eq 0 ]; then
  grep -vE '(^|/)\.[^/.][^/]*(/|$)' "$tmp/dirs" >"$tmp/dirs.keep" || true
  mv "$tmp/dirs.keep" "$tmp/dirs"
fi

# Keep only dirs that still hold Terraform files (a deleted module is not checked).
dirs=()
while read -r d; do
  [ -n "$d" ] && compgen -G "$d/*.tf" >/dev/null && dirs+=("$d")
done <"$tmp/dirs"

if [ "${#dirs[@]}" -eq 0 ]; then
  echo "terraform: skip (no changed Terraform dirs)"
  echo "CHECK: PASS"; exit 0
fi

need terraform terraform || { echo "CHECK: FAIL"; exit 1; }

tflint_ready=0
if ! skipped tflint && need tflint tflint >/dev/null; then
  cfg=()
  [ -f "$root/.tflint.hcl" ] && cfg=(--config "$root/.tflint.hcl")
  if tflint ${cfg[@]+"${cfg[@]}"} --init >"$tmp/tflint-init.txt" 2>&1; then tflint_ready=1; fi
fi

for d in "${dirs[@]}"; do
  echo "== $d"

  if terraform -chdir="$d" fmt -check -recursive -diff >"$tmp/fmt.txt" 2>&1; then
    echo "  fmt:      ok"
  else
    echo "  fmt:      FAIL (run: terraform -chdir=$d fmt -recursive)"; sed 's/^/    /' "$tmp/fmt.txt" | head -40; fail=1
  fi

  # No backend: the gate never reads or locks real state. A committed lock file is
  # read-only here, so the gate never changes provider versions (rule V3).
  lock=()
  [ -f "$d/.terraform.lock.hcl" ] && lock=(-lockfile=readonly)
  if terraform -chdir="$d" init -backend=false -input=false -no-color ${lock[@]+"${lock[@]}"} >"$tmp/init.txt" 2>&1; then
    echo "  init:     ok"
  else
    echo "  init:     FAIL"; tail -20 "$tmp/init.txt" | sed 's/^/    /'; fail=1
    continue
  fi

  if terraform -chdir="$d" validate -no-color >"$tmp/validate.txt" 2>&1; then
    echo "  validate: ok"
  else
    echo "  validate: FAIL"; sed 's/^/    /' "$tmp/validate.txt" | head -40; fail=1
  fi

  if skipped sensitive; then
    echo "  sensitive: SKIP (asked)"
  elif check_sensitive "$d"/*.tf >"$tmp/sensitive.txt" && [ ! -s "$tmp/sensitive.txt" ]; then
    echo "  sensitive: ok"
  else
    echo "  sensitive: FAIL (rule S10)"; sed 's/^/    /' "$tmp/sensitive.txt" | head -40; fail=1
  fi

  if skipped tflint; then
    echo "  tflint:   SKIP (asked)"
  elif ! command -v tflint >/dev/null 2>&1; then
    need tflint tflint; fail=1
  elif [ "$tflint_ready" != 1 ]; then
    echo "  tflint:   FAIL (tflint --init failed)"; sed 's/^/    /' "$tmp/tflint-init.txt" | tail -10; fail=1
  elif tflint ${cfg[@]+"${cfg[@]}"} --chdir="$d" --format=compact >"$tmp/tflint.txt" 2>&1; then
    echo "  tflint:   ok"
  else
    echo "  tflint:   FAIL"; sed 's/^/    /' "$tmp/tflint.txt" | head -40; fail=1
  fi

  if skipped trivy; then
    echo "  trivy:    SKIP (asked)"
  elif ! need trivy trivy; then
    fail=1
  else
    ignore=()
    [ -f "$root/.trivyignore.yaml" ] && ignore=(--ignorefile "$root/.trivyignore.yaml")
    if trivy config --quiet --exit-code 1 --severity "$TRIVY_SEVERITY" ${ignore[@]+"${ignore[@]}"} "$d" >"$tmp/trivy.txt" 2>&1; then
      echo "  trivy:    ok ($TRIVY_SEVERITY)"
    else
      echo "  trivy:    FAIL"; sed 's/^/    /' "$tmp/trivy.txt" | head -60; fail=1
    fi
  fi

  if skipped test; then
    echo "  test:     SKIP (asked)"
  elif [ -f "$d/tests/unit.tftest.hcl" ]; then
    # Unit tests must be mocked. Strip every AWS credential source, so a test that reaches a
    # real provider fails here instead of using someone's session (rule F8).
    if env -u AWS_PROFILE -u AWS_DEFAULT_PROFILE -u AWS_ACCESS_KEY_ID -u AWS_SECRET_ACCESS_KEY \
      -u AWS_SESSION_TOKEN -u AWS_ROLE_ARN -u AWS_WEB_IDENTITY_TOKEN_FILE \
      -u AWS_CONTAINER_CREDENTIALS_FULL_URI -u AWS_CONTAINER_CREDENTIALS_RELATIVE_URI \
      AWS_CONFIG_FILE=/dev/null AWS_SHARED_CREDENTIALS_FILE=/dev/null AWS_EC2_METADATA_DISABLED=true \
      terraform -chdir="$d" test -no-color -filter=tests/unit.tftest.hcl >"$tmp/test.txt" 2>&1; then
      echo "  test:     ok ($(grep -Eo '[0-9]+ passed' "$tmp/test.txt" | tail -1))"
    else
      echo "  test:     FAIL"; grep -vE '^\s*$' "$tmp/test.txt" | tail -40 | sed 's/^/    /'; fail=1
    fi
  else
    echo "  test:     none (add tests/unit.tftest.hcl)"
  fi
done

[ "$fail" = 0 ] && echo "CHECK: PASS" || echo "CHECK: FAIL"
exit "$fail"
