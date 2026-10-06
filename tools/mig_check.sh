#!/usr/bin/env bash
# Builds a save with an OLDER commit of the game, then plays it on the current build.
#   tools/mig_check.sh /path/to/godot [old-commit]
set -eu
GODOT="$1"; OLD="${2:-8af5ed6}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
W="$(mktemp -d)"
SAVES="$HOME/.local/share/godot/app_userdata/One More Life/saves"
KEEP="$(mktemp -d)"
# the older build cannot be told to use a scratch folder, so the real saves are
# moved aside for the duration and put back afterwards
if [ -d "$SAVES" ]; then cp -a "$SAVES/." "$KEEP/"; fi
restore() {
  git -C "$HERE" worktree remove --force "$W/old" 2>/dev/null || true
  rm -rf "${SAVES:?}" && mkdir -p "$SAVES" && cp -a "$KEEP/." "$SAVES/" 2>/dev/null || true
  rm -rf "$W" "$KEEP"
}
trap restore EXIT
git -C "$HERE" worktree add -f "$W/old" "$OLD" -q
cp "$HERE/tools/_mig_make.gd" "$W/old/tools/mig_make.gd"
sed 's#v14_system_test.gd#mig_make.gd#' "$W/old/tools/v14_system_test.tscn" > "$W/old/tools/mig_make.tscn"
rm -rf "${SAVES:?}"/* 2>/dev/null || true
( cd "$W/old" && "$GODOT" --headless --import >/dev/null 2>&1; "$GODOT" --headless res://tools/mig_make.tscn 2>&1 | grep "MIG MAKE" )
( cd "$HERE" && "$GODOT" --headless res://tools/mig_check.tscn 2>&1 | grep -E "MIGRATION FROM|FAIL" )
