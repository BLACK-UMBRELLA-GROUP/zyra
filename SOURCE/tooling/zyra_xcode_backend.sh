#!/bin/sh
set -eu
case "${ZYRA_NO_GIT_ACTIVE:-}" in
  pinned-v1)
    # Xcode can dispatch a phase through a build service. Protect each
    # phase explicitly rather than assuming it shares xcodebuild's parent.
    exec /usr/bin/sandbox-exec -f "${SRCROOT}/../tooling/no_git.sb" \
      /opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/dart \
      "${SRCROOT}/../tooling/zyra_xcode_backend.dart" "$@"
    ;;
  '')
    if [ "${ZYRA_FOUNDER_MANUAL_SDK:-}" = "1" ]; then
      # Only the Founder's explicit run.sh workflow uses the original SDK.
      # The protected AI driver strips this opt-in and denies SDK wrappers.
      exec /bin/sh /opt/homebrew/share/flutter/packages/flutter_tools/bin/xcode_backend.sh "$@"
    fi
    ;;
esac
echo 'Native build requires the checked driver or Founder-operated run.sh.' >&2
exit 64
