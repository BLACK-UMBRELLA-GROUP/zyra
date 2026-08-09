#!/bin/bash
# ZYRA device-run script — safe by default (Fable, 2026-08-01).
#
# Exists because "remember to type --profile" failed twice in two weeks
# (2026-07-19 and 2026-08-01, same symptom both times: plain `flutter run`
# installs a DEBUG build, iOS kills debug/JIT apps when the cable is
# unplugged and refuses to cold-launch them from the icon — looks like
# "the app is broken", is actually build mode). Docs in README.md §Device
# testing; incident history in REPORTS/CURRENT/ZYRA_FABLE_BUILD_REVIEW_
# 2026-07-19_V1.md §7.
#
# Usage (from anywhere):
#   ./run.sh           -> PROFILE build (default) — survives unplugging,
#                         launches from the icon, safe to walk around with.
#   ./run.sh dev       -> DEBUG build + hot reload — ONLY while the cable
#                         stays plugged in. Unplugging kills it by design.
#   ./run.sh release   -> Release build — what real users would get.
#
# AI sessions: tell Shakeel to run `./run.sh`, nothing else, unless he
# explicitly wants tethered hot-reload work (then `./run.sh dev`).

cd "$(dirname "$0")" || exit 1

DEVICE="00008130-001A2C1E26F8001C"   # Shakeel's iPhone (check: flutter devices)
MODE="${1:-profile}"

# HARDENED 2026-08-01 (Opus). The device id above is hardcoded, so the day
# it stops matching — new phone, restored device, re-pairing — `flutter run`
# fails with "No supported devices found with name or id matching...".
# That error reads almost exactly like the debug-build bug this script
# exists to prevent, so it would send the next session chasing the wrong
# thing entirely. Printed only on failure, so it costs nothing on a normal
# run (a pre-flight `flutter devices` check would add 3-8s to EVERY launch,
# which isn't worth it for a rare failure).
_hint() {
  echo ""
  echo "⚠️  That didn't start. If the message above mentions no matching device:"
  echo "   • Is the iPhone plugged in, unlocked, and trusted?"
  echo "   • Changed phones? Run: flutter devices"
  echo "     then update DEVICE at the top of this script."
  echo "   This is NOT the debug-build problem — that one installs fine and"
  echo "   only dies after you unplug."
  echo ""
  exit 1
}

case "$MODE" in
  dev|debug)
    echo ""
    echo "⚠️  DEBUG MODE — keep the cable plugged in."
    echo "   If you unplug, the app dies and won't reopen from the icon"
    echo "   until you run ./run.sh again. For untethered testing use: ./run.sh"
    echo ""
    flutter run -d "$DEVICE" || _hint
    ;;
  release)
    flutter run --release -d "$DEVICE" || _hint
    ;;
  profile|*)
    echo ""
    echo "✅ PROFILE MODE — once the app opens on the phone you can unplug,"
    echo "   close it, and reopen it from the icon like a normal app."
    echo "   (No hot reload — rerun this script to pick up code changes.)"
    echo ""
    flutter run --profile -d "$DEVICE" || _hint
    ;;
esac
