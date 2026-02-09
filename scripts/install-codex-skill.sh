#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$REPO_ROOT/skills/markdown-linter-fixer"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
DEST_DIR="$CODEX_HOME/skills/markdown-linter-fixer"

if [[ ! -f "$SRC_DIR/SKILL.md" ]]; then
  echo "Error: SKILL.md not found at $SRC_DIR"
  exit 1
fi

mkdir -p "$CODEX_HOME/skills"
rm -rf "$DEST_DIR"
cp -R "$SRC_DIR" "$DEST_DIR"

echo "Installed markdown-linter-fixer skill to: $DEST_DIR"
echo "Next: restart Codex CLI (or start a new session) so it reloads skills."
