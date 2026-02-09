#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="markdown-linter-fixer"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
DEST_DIR="$CODEX_HOME/skills/$SKILL_NAME"

if [[ ! -e "$DEST_DIR" ]]; then
  echo "Skill is not installed at: $DEST_DIR"
  echo "Nothing to uninstall."
  exit 0
fi

rm -rf "$DEST_DIR"
echo "Uninstalled $SKILL_NAME from: $DEST_DIR"
echo "Next: restart Codex CLI (or start a new session) so it reloads skills."
