#!/usr/bin/env bash
# The App Store screenshots: capture the real app on an iPhone 17 Pro Max
# simulator (6.9", native 1320x2868), then frame each capture with its
# headline in the store's style (frame.swift).
#
#   Tools/AppStore/screenshots/capture.sh [--out DIR] [--only NN] [--frame-only] [--keep]
#
# The scenes, their launch variables and their words are in scenes.txt.
# Every scene opens with a debug build's launch variables
# (LUMEN_VIAE_TAB, LUMEN_VIAE_ROUTE, LUMEN_VIAE_CHANT, LUMEN_VIAE_TODAY;
# AppRouter), so nothing is tapped and a run is repeatable.
#
#   --out DIR     where to write (default .build/screenshots): raw/NN.png,
#                 the captures, and NN.png, the framed screenshots
#   --only NN     one scene
#   --frame-only  frame the captures already in DIR/raw, capture nothing
#   --keep        leave the simulator booted afterwards
#
# Upload with: Tools/dev asc screenshots <version> --dir DIR (a dry run
# until --confirm). The simulator is this tool's own ("LumenViae
# Screenshots"), never the booted one other sessions drive.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
HERE="$ROOT/Tools/AppStore/screenshots"
cd "$ROOT"

OUT="$ROOT/.build/screenshots"
ONLY=""
FRAME_ONLY=0
KEEP=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --out) mkdir -p "$2"; OUT="$(cd "$2" && pwd)"; shift 2 ;;
    --only) ONLY="$2"; shift 2 ;;
    --frame-only) FRAME_ONLY=1; shift ;;
    --keep) KEEP=1; shift ;;
    -h|--help) sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option $1" >&2; exit 2 ;;
  esac
done

SIM_NAME="LumenViae Screenshots"
SIM_DEVICE="iPhone 17 Pro Max"
BUNDLE_ID="com.lumenviae.app"
DERIVED="$ROOT/.build/DerivedData"
mkdir -p "$OUT/raw" "$ROOT/.build/logs"

note() { printf '%s\n' "$*"; }
run() { printf '+ '; printf '%q ' "$@"; printf '\n'; "$@"; }

# The scenes: NN|launch variables (space separated)|seconds to settle|line 1|line 2|subline
scenes() { grep -v '^\s*#' "$HERE/scenes.txt" | grep -v '^\s*$'; }

sim_udid() {
  local udid
  udid="$(xcrun simctl list devices -j | python3 -c '
import json, sys
for devices in json.load(sys.stdin)["devices"].values():
    for d in devices:
        if d["name"] == sys.argv[1] and d.get("isAvailable", True):
            print(d["udid"]); raise SystemExit
' "$SIM_NAME")"
  if [[ -z "$udid" ]]; then
    local runtime
    runtime="$(xcrun simctl list runtimes -j | python3 -c '
import json, sys
ios = [r for r in json.load(sys.stdin)["runtimes"] if r["platform"] == "iOS" and r["isAvailable"]]
print(sorted(ios, key=lambda r: [int(p) for p in r["version"].split(".")])[-1]["identifier"] if ios else "")
')"
    note "creating simulator \"$SIM_NAME\" ($SIM_DEVICE, $runtime)" >&2
    udid="$(xcrun simctl create "$SIM_NAME" "$SIM_DEVICE" "$runtime")"
  fi
  printf '%s' "$udid"
}

capture() {
  local udid
  udid="$(sim_udid)"
  if command -v sim-cap >/dev/null && ! xcrun simctl list devices | grep -q "$udid) (Booted)"; then
    sim-cap ok "$udid" || { echo "too many simulators booted (sim-cap list); try again later" >&2; exit 75; }
  fi
  xcrun simctl list devices | grep -q "$udid) (Booted)" || run xcrun simctl boot "$udid"
  run xcrun simctl bootstatus "$udid" -b >/dev/null
  run xcrun simctl ui "$udid" appearance dark
  run xcrun simctl status_bar "$udid" override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 --operatorName "" --batteryState discharging --batteryLevel 100

  local log="$ROOT/.build/logs/screenshots-build.log"
  note "building (Debug, for the launch variables; log: ${log#"$ROOT"/})"
  if ! xcodebuild build -project app.xcodeproj -scheme app -configuration Debug \
      -destination "id=$udid" -derivedDataPath "$DERIVED" >"$log" 2>&1; then
    grep -E 'error:' "$log" | sort -u | head -20; tail -10 "$log"; exit 1
  fi
  local app="$DERIVED/Build/Products/Debug-iphonesimulator/app.app"
  [[ -d "$app" ]] || app="$(find "$DERIVED/Build/Products/Debug-iphonesimulator" -maxdepth 1 -name '*.app' | head -1)"
  run xcrun simctl install "$udid" "$app"
  local version
  version="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$app/Info.plist")"

  # A reader who has been through the introduction, seen this version's
  # notes and the tour, and answered the one-time questions
  local prefs
  prefs="$(xcrun simctl get_app_container "$udid" "$BUNDLE_ID" data)/Library/Preferences/$BUNDLE_ID"
  xcrun simctl terminate "$udid" "$BUNDLE_ID" 2>/dev/null || true
  local d=(xcrun simctl spawn "$udid" defaults write "$prefs")
  "${d[@]}" hasSeenOnboarding -bool true
  "${d[@]}" whatsNew.lastVersionSeen -string "$version"
  "${d[@]}" firstUseTour.due -bool false
  "${d[@]}" userSettings.missalLayout -string interlinear
  "${d[@]}" userSettings.hasSeenPrayerSwipeHint -bool true
  "${d[@]}" userSettings.prayAloud -bool false
  "${d[@]}" prayerBook.aloud -bool false

  # A first launch fetches the server's content and settles; then each scene
  run xcrun simctl launch "$udid" "$BUNDLE_ID" >/dev/null
  sleep 8

  while IFS='|' read -r nn vars settle _; do
    [[ -n "$ONLY" && "$nn" != "$ONLY" ]] && continue
    xcrun simctl terminate "$udid" "$BUNDLE_ID" 2>/dev/null || true
    # No Rosary left part-way by an earlier scene, so home has no resume card
    xcrun simctl spawn "$udid" defaults delete "$prefs" prayerResume.inProgress 2>/dev/null || true
    local env=()
    for v in $vars; do env+=("SIMCTL_CHILD_LUMEN_VIAE_$v"); done
    note "scene $nn: ${vars:-home}"
    env "${env[@]}" xcrun simctl launch "$udid" "$BUNDLE_ID" >/dev/null
    sleep "$settle"
    xcrun simctl io "$udid" screenshot --type=png "$OUT/raw/$nn.png" >/dev/null 2>&1
  done < <(scenes)

  xcrun simctl terminate "$udid" "$BUNDLE_ID" 2>/dev/null || true
  xcrun simctl status_bar "$udid" clear
  [[ $KEEP == 1 ]] || run xcrun simctl shutdown "$udid"
}

frame() {
  local bin="$ROOT/.build/screenshots-frame"
  if [[ ! -x "$bin" || "$HERE/frame.swift" -nt "$bin" ]]; then
    run xcrun swiftc -O "$HERE/frame.swift" -o "$bin"
  fi
  while IFS='|' read -r nn _ _ line1 line2 subline; do
    [[ -n "$ONLY" && "$nn" != "$ONLY" ]] && continue
    [[ -f "$OUT/raw/$nn.png" ]] || { echo "no capture for scene $nn in $OUT/raw" >&2; exit 1; }
    "$bin" "$OUT/raw/$nn.png" "$OUT/$nn.png" "$line1|$line2" "$subline"
    note "framed $nn: $line1 / $line2"
  done < <(scenes)
}

[[ $FRAME_ONLY == 1 ]] || capture
frame
note "screenshots in ${OUT#"$ROOT"/}"
