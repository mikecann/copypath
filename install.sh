#!/usr/bin/env bash
# Symlink the macOS launcher from this clone into a directory on PATH.
set -euo pipefail

if [[ $# -gt 1 || ${1:-} == -* ]]; then
  echo "Usage: bash install.sh [target_bin_dir]" >&2
  exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-$HOME/.local/bin}"
mkdir -p "$TARGET_DIR"
chmod +x "$REPO_DIR/copypath"
ln -sf "$REPO_DIR/copypath" "$TARGET_DIR/copypath"
echo "Installed $TARGET_DIR/copypath -> $REPO_DIR/copypath"

case ":$PATH:" in
  *":$TARGET_DIR:"*) ;;
  *)
    echo "Add this to ~/.zshrc or ~/.bashrc, then open a new terminal:"
    printf 'export PATH="%s:$PATH"\n' "$TARGET_DIR"
    ;;
esac
