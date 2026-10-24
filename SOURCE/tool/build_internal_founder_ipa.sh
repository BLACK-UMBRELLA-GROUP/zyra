#!/bin/sh
# Local export only. Same ZYRA bundle; exact authenticated Founder gets local
# previews. Apple upload and distribution are separate, artifact-bound steps.
set -eu
cd "$(dirname "$0")/.."
if [ "$#" -ne 2 ]; then
  echo 'Usage: sh tool/build_internal_founder_ipa.sh <version> <build-number>'
  exit 64
fi
zyra_version="$1"
zyra_build="$2"
case "$zyra_version" in ''|*[!0-9.]*|.*|*..*|*.) exit 64;; esac
case "$zyra_build" in ''|*[!0-9]*|0) exit 64;; esac

# Never use an external/public export configuration for this compile flag.
test "$(/usr/libexec/PlistBuddy -c 'Print :testFlightInternalTestingOnly' ios/TestFlightInternalExportOptions.plist)" = true
test "$(/usr/libexec/PlistBuddy -c 'Print :destination' ios/TestFlightInternalExportOptions.plist)" = export
test "$(/usr/libexec/PlistBuddy -c 'Print :teamID' ios/TestFlightInternalExportOptions.plist)" = 9Y7Z8F36SJ
test "$(/usr/libexec/PlistBuddy -c 'Print :manageAppVersionAndBuildNumber' ios/TestFlightInternalExportOptions.plist)" = false

flutter build ipa --no-pub --release --flavor production \
  --build-name="$zyra_version" --build-number="$zyra_build" \
  --dart-define=ZYRA_INTERNAL_FOUNDER_ACCESS=true \
  --dart-define=ZYRA_INTERNAL_FOUNDER_UUID=dfcbd00d-bc22-4d6e-999b-3a9264cf3510 \
  --export-options-plist=ios/TestFlightInternalExportOptions.plist
