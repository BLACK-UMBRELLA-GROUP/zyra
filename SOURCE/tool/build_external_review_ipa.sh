#!/bin/sh
# Local export only. Upload and TestFlight App Review submission remain
# separate, artifact-bound actions. This build exposes local sample data only.
set -eu
cd "$(dirname "$0")/.."
if [ "$#" -ne 2 ]; then
  echo 'Usage: sh tool/build_external_review_ipa.sh <version> <build-number>'
  exit 64
fi
zyra_version="$1"
zyra_build="$2"
case "$zyra_version" in ''|*[!0-9.]*|.*|*..*|*.) exit 64;; esac
case "$zyra_build" in ''|*[!0-9]*|0) exit 64;; esac

options=ios/TestFlightExternalExportOptions.plist
test "$(/usr/libexec/PlistBuddy -c 'Print :destination' "$options")" = export
test "$(/usr/libexec/PlistBuddy -c 'Print :teamID' "$options")" = 9Y7Z8F36SJ
test "$(/usr/libexec/PlistBuddy -c 'Print :manageAppVersionAndBuildNumber' "$options")" = false
if /usr/libexec/PlistBuddy -c 'Print :testFlightInternalTestingOnly' "$options" >/dev/null 2>&1; then
  echo 'External TestFlight export must not be internal-testing-only.'
  exit 65
fi

flutter build ipa --no-pub --release --flavor production \
  --build-name="$zyra_version" --build-number="$zyra_build" \
  --dart-define=ZYRA_EXTERNAL_TESTER_ACCESS=true \
  --export-options-plist="$options"
