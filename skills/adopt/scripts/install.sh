#!/usr/bin/env bash
# Step 1 of the `adopt` skill: copy the templates (and the day-to-day skills, if they sit
# next to this skill) into a project. Safe on legacy repos: it NEVER overwrites a file. If a
# file already exists, the template version goes to .agentic/incoming/<path> for merging.
#
# Usage: install.sh [--dry-run] [TARGET_DIR]     (TARGET_DIR defaults to .)
set -euo pipefail

dry=0
if [ "${1:-}" = "--dry-run" ]; then dry=1; shift; fi
skill="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"   # .../skills/adopt
skills_root="$(dirname "$skill")"                          # .../skills
target="$(cd "${1:-.}" && pwd)"

if ! top="$(git -C "$target" rev-parse --show-toplevel 2>/dev/null)"; then
  echo "error: $target is not a git repository (the gate needs git). Run 'git init' first." >&2
  exit 1
fi
case "$skill/" in
  "$top"/*) echo "error: target is the agentic-coding-resources repo itself. Pass your project's path." >&2; exit 1 ;;
esac

# place SOURCE_FILE REL_PATH — copy to TARGET/REL_PATH, or to .agentic/incoming on conflict.
place() {
  local from="$1" rel="$2" dest="$target/$2"
  if [ -e "$dest" ]; then
    if cmp -s "$from" "$dest"; then echo "  same     $rel"; return; fi
    dest="$target/.agentic/incoming/$rel"
    echo "  exists   $rel  -> template saved to .agentic/incoming/$rel"
  else
    echo "  add      $rel"
  fi
  if [ "$dry" = 0 ]; then
    mkdir -p "$(dirname "$dest")"
    cp -p "$from" "$dest"
  fi
}

echo "Installing into $target$([ "$dry" = 1 ] && echo ' (dry run)')"

# Templates keep their relative paths (AGENTS.md, scripts/check.sh, .claude/..., ...).
(cd "$skill/templates" && find . -type f | sed 's|^\./||' | sort) | while read -r rel; do
  place "$skill/templates/$rel" "$rel"
done

# Day-to-day skills become project skills, so teammates and other agents get them too.
# Named explicitly: if this skill was copied alone into ~/.claude/skills, its siblings are the
# user's personal skills and must NOT be copied. `adopt` itself is one-time and not copied.
for name in gate-driven-slices adversarial-review security-audit memory-discipline condensed-plans; do
  [ -f "$skills_root/$name/SKILL.md" ] && place "$skills_root/$name/SKILL.md" ".claude/skills/$name/SKILL.md"
done

if [ "$dry" = 0 ]; then
  chmod +x "$target/scripts/check.sh" 2>/dev/null || true
  # The exact placeholder strings, so `adopt` can prove none is left after filling.
  mkdir -p "$target/.agentic"
  (cd "$skill/templates" && grep -rohE '<[A-Za-z][^<>]*>' . | sort -u) >"$target/.agentic/placeholders.txt"
  grep -qx '/.agentic/' "$target/.gitignore" 2>/dev/null \
    || printf '\n# agentic-coding adopt staging (deleted when adopt finishes)\n/.agentic/\n' >>"$target/.gitignore"
fi
echo "Copied. Continue with the adopt skill, step 2."
