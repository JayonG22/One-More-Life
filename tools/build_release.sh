#!/usr/bin/env bash
# Builds Windows, macOS and Linux and packs a release folder.
#   tools/build_release.sh /path/to/godot /path/to/output-dir
#
# Needs the Godot 4.4.1 export templates installed. For the Windows icon and
# version info, rcedit must be configured in Godot's editor settings (on Linux that
# means rcedit-x64.exe run through Wine).
set -euo pipefail
GODOT="$1"; OUT="${2:-build}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
VER="$(grep -m1 '^config/version' "$HERE/project.godot" | sed 's/.*"\(.*\)"/\1/')"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"
PKG="$OUT/OneMoreLife-v$VER"
if [ -e "$PKG" ]; then
  echo "Output already exists: $PKG. Choose a new output folder." >&2
  exit 1
fi
mkdir -p "$PKG/Game/Windows" "$PKG/Game/macOS" "$PKG/Game/Linux" "$PKG/Source"
cd "$HERE"
"$GODOT" --headless --import >/dev/null 2>&1
export_platform() {
  local preset="$1" destination="$2" label="$3"
  local log="$PKG/export-$label.log"
  if ! "$GODOT" --headless --export-release "$preset" "$destination" >"$log" 2>&1; then
    cat "$log" >&2
    echo "Export failed: $preset. No completed release was produced." >&2
    exit 1
  fi
  if [ ! -s "$destination" ] || grep -qE '^ERROR|SCRIPT ERROR|Parse Error' "$log"; then
    cat "$log" >&2
    echo "Export invalid: $preset. Check templates and export settings." >&2
    exit 1
  fi
}
export_platform "Linux" "$PKG/Game/Linux/OneMoreLife.x86_64" linux
export_platform "Windows Desktop" "$PKG/Game/Windows/OneMoreLife.exe" windows
export_platform "macOS" "$PKG/Game/macOS/OneMoreLife-macOS.zip" macos
chmod +x "$PKG/Game/Linux/OneMoreLife.x86_64"
# the source, without the editor's cache or the git history
git -C "$HERE" archive HEAD | tar -x -C "$PKG/Source"
cp "$HERE/docs/history/CHANGELOG.md" "$PKG/CHANGELOG.md"
cp "$HERE/CREDITS.md" "$PKG/"
mkdir -p "$PKG/fonts"
cp "$HERE"/fonts/LICENSE-*.txt "$PKG/fonts/"
ls -la "$PKG/Game"/*
echo "built $PKG"
