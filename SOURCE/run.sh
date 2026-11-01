#!/bin/bash
# ZYRA device-run script — safe by default (Fable, 2026-08-01).
#
# Exists because "remember to type --profile" failed twice in two weeks
# (2026-07-19 and 2026-08-01, same symptom both times: plain `flutter run`
# installs a DEBUG build, iOS kills debug/JIT apps when the cable is
# unplugged and refuses to cold-launch them from the icon — looks like
# "the app is broken", is actually build mode). Docs in README.md §Device
# testing; incident history in REPORTS/ARCHIVE/ZYRA_FABLE_BUILD_REVIEW_
# 2026-07-19_V1.md §7.
#
# Usage (from anywhere):
#   ./run.sh           -> main ZYRA PROFILE build (default) — survives
#                         unplugging. The exact authenticated Founder gets
#                         local-only previews; personal accounts stay normal.
#   ./run.sh dev       -> the same main ZYRA identity in DEBUG mode + hot
#                         reload — ONLY while the cable stays plugged in.
#   ./run.sh release   -> public main ZYRA release-mode device check. It has
#                         no Founder opt-in and no Developer Access.
#
# Founder-operated legacy SDK route; AI sessions never invoke this script.
# The SDK wrappers may run Git. AI checks/native PROFILE preparation use
# tooling/no_git_driver.mjs under its inherited OS process-exec policy.

cd "$(dirname "$0")" || exit 1

DEVICE="${ZYRA_DEVICE_ID:-}"
FOUNDER_UUID="${ZYRA_INTERNAL_FOUNDER_UUID:-}"
MODE="${1:-profile}"

_require_device() {
  if [ -z "$DEVICE" ]; then
    echo "Set ZYRA_DEVICE_ID to the intended device identifier (flutter devices)."
    exit 64
  fi
}

_run_internal_founder() {
  _require_device
  if [ -z "$FOUNDER_UUID" ]; then
    echo "Set ZYRA_INTERNAL_FOUNDER_UUID to the approved Founder account UUID."
    exit 64
  fi
  flutter run \
    --flavor production \
    --dart-define=ZYRA_INTERNAL_FOUNDER_ACCESS=true \
    --dart-define=ZYRA_INTERNAL_FOUNDER_UUID="$FOUNDER_UUID" \
    "$@" || _hint
}

# Show pairing guidance only after a failed run; device identifiers stay local.
_hint() {
  echo ""
  echo "⚠️  That didn't start. If the message above mentions no matching device:"
  echo "   • Is the iPhone plugged in, unlocked, and trusted?"
  echo "   • Changed phones? Run: flutter devices"
  echo "     then export ZYRA_DEVICE_ID with the intended identifier."
  echo "   This is NOT the debug-build problem — that one installs fine and"
  echo "   only dies after you unplug."
  echo ""
  exit 1
}

case "$MODE" in
  check-founder-test-config|test|foundertest|founder-test)
    echo ""
    echo "🛑 The separate ZYRA Test target is retired. Nothing was run."
    echo ""
    exit 64
    ;;
  dev|debug)
    echo ""
    echo "⚠️  DEBUG MODE — keep the cable plugged in."
    echo "   If you unplug, the app dies and won't reopen from the icon"
    echo "   until you run ./run.sh again. For untethered testing use: ./run.sh"
    echo ""
    _run_internal_founder -d "$DEVICE"
    ;;
  release)
    echo ""
    echo "🔒 PRODUCTION ZYRA — Developer Access is disabled."
    echo ""
    _require_device
    flutter run --release --flavor production -d "$DEVICE" || _hint
    ;;
  profile)
    echo ""
    echo "✅ PROFILE MODE — once the app opens on the phone you can unplug,"
    echo "   close it, and reopen it from the icon like a normal app."
    echo "   (No hot reload — rerun this script to pick up code changes.)"
    echo ""
    _run_internal_founder --profile -d "$DEVICE"
    ;;
  *)
    echo ""
    echo "🛑 Unknown run mode '$MODE'. Nothing was run."
    echo "   Use: ./run.sh, ./run.sh dev, or ./run.sh release"
    echo ""
    exit 64
    ;;
esac
