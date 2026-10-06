#!/usr/bin/env bash
# ONE MORE LIFE — the release gate. Runs every automated check against a throwaway
# save folder (OML_USER_DIR) so it never touches real saves, and prints one verdict.
#
#   tools/run_gates.sh /path/to/Godot_v4.4.1-stable_linux.x86_64
#
# Headless gates run directly; screen checks run under xvfb. All checks are silent.
set -u
GODOT="${1:-godot}"
cd "$(dirname "$0")/.."
export OML_USER_DIR="$(mktemp -d)"
trap 'rm -rf "${OML_USER_DIR:?}"' EXIT
pass=0; fail=0; failed=()

run() {  # name, scene, pattern-that-must-appear, pattern-that-must-not, [xvfb]
  local name="$1" scene="$2" must="$3" mustnot="$4" screen="${5:-}"
  local out status
  if [ -n "$screen" ]; then
    out="$(timeout 1500 xvfb-run -a -s '-screen 0 1600x900x24' "$GODOT" --audio-driver Dummy --rendering-driver opengl3 "res://tools/$scene.tscn" 2>&1)"
  else
    out="$(timeout 1500 "$GODOT" --headless --audio-driver Dummy "res://tools/$scene.tscn" 2>&1)"
  fi
  status=$?
  local line; line="$(printf '%s\n' "$out" | grep -E "$must" | tail -1)"
  if [ "$status" -eq 0 ] && [ -n "$line" ] && ! printf '%s\n' "$out" | grep -qE "$mustnot|SCRIPT ERROR|Parse Error"; then
    printf '  PASS  %-16s %s\n' "$name" "$line"; pass=$((pass+1))
  else
    printf '  FAIL  %-16s %s\n' "$name" "${line:-no result line}"; fail=$((fail+1)); failed+=("$name")
    printf '%s\n' "$out" | grep -E "FAIL|ERROR|SCRIPT" | head -5 | sed 's/^/          /'
  fi
}

echo "ONE MORE LIFE — release gate"
"$GODOT" --headless --import >/dev/null 2>&1
run v0.8  v08_system_test 'failures=0' 'FAIL:'
run echo  v08_echo_test   'failures=0' 'FAIL:'
run v0.9  v09_system_test 'failures=0' 'FAIL:'
run v0.10 v10_system_test 'failures=0' 'FAIL:'
run v0.11 v11_system_test 'failures=0' 'FAIL:'
run v0.12 v12_content_test 'failures=0' 'FAIL:'
run v0.13 v13_moments_test 'failures=0' 'FAIL:'
run v0.14 v14_system_test 'failures=0' 'FAIL:'
run v0.15 v15_system_test 'failures=0' 'FAIL:'
run v0.16 v16_system_test 'failures=0' 'FAIL:'
run arcs  v17_arcs_test   'failures=0' 'FAIL:'
run echo2 v18_echo_test   'failures=0' 'FAIL:'
run pets  v19_pets_test   'failures=0' 'FAIL:'
run prison v20_prison_test 'failures=0' 'FAIL:'
run v21 v21_test 'failures=0' 'FAIL:'
run migrate migrate_test  'MIGRATION OK' 'MIGRATION FAIL'
run sim   sim_test        'SIM DONE' 'SCRIPT ERROR'
run crawl menu_crawl      'CRAWL DONE' 'SCRIPT ERROR'
run layout layout_audit   'problems=0' 'SCRIPT ERROR'
run perf  perf_test        'PERF TEST' 'FAIL:'
run a11y  a11y_test       'failures=0' 'FAIL:' screen
run v25 v25_events_test 'failures=0' 'FAIL:|SCRIPT ERROR'
run v26 v26_test 'failures=0' 'FAIL:|SCRIPT ERROR'
run v26ui v26_ui_test 'failures=0' 'FAIL:|SCRIPT ERROR' screen
run v27 v27_test 'failures=0' 'FAIL:|SCRIPT ERROR'
run v27ui v27_ui_test 'failures=0' 'FAIL:|SCRIPT ERROR' screen
run v28 v28_test 'failures=0' 'FAIL:|SCRIPT ERROR'
run v28ui v28_ui_test 'failures=0' 'FAIL:|SCRIPT ERROR' screen
run v29 v29_test 'failures=0' 'FAIL:|SCRIPT ERROR'
run v29ui v29_ui_test 'failures=0' 'FAIL:|SCRIPT ERROR' screen
run v30 v30_test 'failures=0' 'FAIL:|SCRIPT ERROR'
run v30ui v30_ui_test 'failures=0' 'FAIL:|SCRIPT ERROR' screen
run depth depth_test 'failures=0' 'FAIL:|SCRIPT ERROR'
run depthui depth_ui_test 'failures=0' 'FAIL:|SCRIPT ERROR' screen
run v31 v31_test 'failures=0' 'FAIL:|SCRIPT ERROR'
run shopping shopping_test 'failures=0' 'FAIL:|SCRIPT ERROR'
run shoppingui shopping_ui_test 'failures=0' 'FAIL:|SCRIPT ERROR' screen
run v31ui v31_ui_test 'failures=0' 'FAIL:|SCRIPT ERROR' screen
run gamble gamble_test 'failures=0' 'FAIL:|SCRIPT ERROR' screen
run minigames mg_smart    'MG GATE PASS' 'MG GATE FAIL|SCRIPT ERROR' screen
run input mg_input_probe  'MG INPUT PROBE PASS' 'FAIL' screen
run ui    ui_test         'UI TEST DONE, screen=graveyard' 'SCRIPT ERROR' screen
run petsui v19_ui_test    'failures=0' 'FAIL:|SCRIPT ERROR' screen
run prisonui v20_ui_test  'failures=0' 'FAIL:|SCRIPT ERROR' screen

echo
if [ "$fail" -eq 0 ]; then echo "GATE: ALL $pass GREEN"; else echo "GATE: $fail FAILED (${failed[*]}) of $((pass+fail))"; fi
exit "$fail"
