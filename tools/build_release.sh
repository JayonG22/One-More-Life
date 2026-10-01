#!/usr/bin/env bash
# Builds Windows, macOS and Linux and packs a release folder.
#   tools/build_release.sh /path/to/godot /path/to/output-dir
#
# Needs the Godot 4.4.1 export templates installed. For the Windows icon and
# version info, rcedit must be configured in Godot's editor settings (on Linux that
# means rcedit-x64.exe run through Wine).
set -eu
GODOT="$1"; OUT="${2:-build}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
VER="$(grep -m1 '^config/version' "$HERE/project.godot" | sed 's/.*"\(.*\)"/\1/')"
PKG="$OUT/OneMoreLife-v$VER"
rm -rf "${PKG:?}"
mkdir -p "$PKG/Game/Windows" "$PKG/Game/macOS" "$PKG/Game/Linux" "$PKG/Source"
cd "$HERE"
"$GODOT" --headless --import >/dev/null 2>&1
"$GODOT" --headless --export-release "Linux"           "$PKG/Game/Linux/OneMoreLife.x86_64" 2>&1 | grep -iE "^ERROR" || true
"$GODOT" --headless --export-release "Windows Desktop" "$PKG/Game/Windows/OneMoreLife.exe"   2>&1 | grep -iE "^ERROR" || true
"$GODOT" --headless --export-release "macOS"           "$PKG/Game/macOS/OneMoreLife-macOS.zip" 2>&1 | grep -iE "^ERROR" || true
chmod +x "$PKG/Game/Linux/OneMoreLife.x86_64"
# the source, without the editor's cache or the git history
git -C "$HERE" archive HEAD | tar -x -C "$PKG/Source"
cp "$HERE/docs/history/CHANGELOG.md" "$PKG/CHANGELOG.md"
cp "$HERE/CREDITS.md" "$PKG/"
mkdir -p "$PKG/fonts"
cp "$HERE"/fonts/LICENSE-*.txt "$PKG/fonts/"
ls -la "$PKG/Game"/*
echo "built $PKG"
