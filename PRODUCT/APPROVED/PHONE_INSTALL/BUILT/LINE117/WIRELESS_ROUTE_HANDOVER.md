---
id: ASBUILT-ZYRA-LINE117-WIRELESS
type: HANDOVER
status: CURRENT
feature: PHONE DELIVERY
purpose: Explicit wireless delivery on the protected signed Founder iPhone route
links: [DOC-ZYRA-0514, DOC-ZYRA-0448, OA-ZYRA-317, DR-ZYRA-352]
owner: Codex
---

# Protected wireless iPhone delivery

Founder authority on 19 Nov 2026 was “Push wirelessly please.” The selected transport belongs to one command invocation. The dispatcher instructed implementation and verification of this route before the fresh native build, with a separate GO required for installation of that measured build.

SOURCE/tooling/verified_phone_delivery.mjs selects the sole profile-matched iPhone and checks pairing, requested transport and a live unlock response. For wireless, an initially idle localNetwork tunnel may reconnect during that read-only query. A second inventory must identify the same paired phone with the same transport and a connected tunnel. The sequence runs before installation, before launch and after launch. USB remains the default and requires a connected wired tunnel at its first check.

SOURCE/tooling/verified_host_profile.mjs accepts one final --wireless flag on its native phone check and native delivery commands. Exact source seal, artifact digest, profile, certificate, entitlements and successful native build receipt remain prerequisites. The signed app must claim exactly applinks:zyraconnect.app. Unexpected CLI arguments and a missing receipt fail before delivery. Legacy entry points use wired transport.

    node tooling/verified_host_profile.mjs native-phone-check <CHECKED_PREBUILD.json> --wireless
    node tooling/verified_host_profile.mjs native-deliver <CHECKED_PREBUILD.json> <receipt-sha256> --wireless

The first command reads readiness. Run the second only after the Founder gives GO for the identified signed build. The delivery receipt records transport and separate install, launch and final-verification flags. Device identifiers and raw CoreDevice responses stay in memory. A changed device, lock state, connection, artifact or receipt stops the operation. An attempted install stays recorded and the protected route refuses another attempt against that receipt automatically.

SOURCE/tooling/verified_phone_delivery.test.mjs uses synthetic subprocess responses to check wired default, explicit wireless, idle-tunnel wake, pairing and profile membership, ambiguous inventory, lock and identity drift, artifact and install/launch receipt validation, stage ordering and failure receipts. verified_host_profile.test.mjs checks exact CLI flag placement and receipt arity alongside its existing signing and artifact checks. review_workspace.test.mjs checks protected workspace boundaries.

Local verification on 19 Nov passed 75 phone-route tests and 24 host/workspace tests. Flutter analyzer was clean and 168 focused profile-video/code tests passed. Independent route review passed. The read-only live wireless probe identified the provisioned paired phone, verified unlocked state and observed its connected localNetwork tunnel.

The fresh signed build, its measured pins and its installation are pending. Line 117 remains WAITING until its required phone checks finish. Continue under DOC-ZYRA-0514, Q157/Q158/Q162 and OA-ZYRA-317. The one approved native build must use cached pins and restore the temporary Xcode preference on success or failure. App code, live server changes, uploads and migrations are outside this route change.
