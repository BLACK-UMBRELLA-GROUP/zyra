# 132 — CODEX → FOUNDER

**Date:** 2026-09-17  
**Subject:** First-time onboarding account switch added; corrected profile build installed and launched on iPhone  
**Decision / action:** DR-ZYRA-221 / OA-ZYRA-266 / OA-ZYRA-286  
**Status:** IMPLEMENTED, INTERNALLY VERIFIED, INSTALLED AND LAUNCHED; FOUNDER INTERACTION ACCEPTANCE PENDING

## 1. Outcome

ZYRA now exposes **Use a different account** throughout first-time setup: role
selection, both roles' initial overview/question screens and every identity-
verification state. The action confirms before proceeding, clears only the
active account's unfinished protected setup and local session on the current
device, and returns to Welcome. It does not delete the account or server data.

Completed members retain the conventional **Sign out** action in
Account/Profile. Developer previews, duplicate-account resolution and later
progressive onboarding do not show the new first-time-setup escape.

## 2. Security and account boundaries

- The route captures the expected authenticated user ID and rechecks it before
  cleanup and logout. A route created for account A cannot sign out a replacement
  principal B.
- Supabase logout is explicit `SignOutScope.local`, preserving independent
  sessions on other devices.
- Only the active account's protected unfinished-signup draft is erased; a
  different account's draft is preserved.
- When Google is linked, ZYRA clears google_sign_in's app-local remembered
  chooser identity with `signOut()`. It never calls grant-revoking
  `disconnect()`.
- Google-provider detection accepts identities plus server-controlled
  `app_metadata.provider` and `app_metadata.providers`, normalized to lowercase.
- A best-effort Google chooser-reset failure cannot block ZYRA's own secure
  local cleanup.

## 3. Verification

| Check | Result |
|---|---|
| Focused onboarding/auth suite | PASS — 117 tests, one compile-gated skip, zero failures |
| Whole-tree analyzer | PASS — no issues |
| Full repository suite | NOT GREEN — 1,602 passed, one skipped, 100 existing unrelated dashboard/developer/visual failures |
| Database/provider/migration change | NONE |
| TestFlight/App Store upload | NONE |
| Git operation | NONE |

Focused coverage includes cancel-without-mutation, exactly one Google chooser
reset and one local Supabase logout, account-scoped draft deletion, preservation
of another account's draft, metadata-only Google-provider detection, principal
replacement denial, all intended Seeker/Guardian/IDV surfaces, preview
suppression, the Seeker second-intro surface and a working Guardian-overview Back
route.

## 4. iPhone delivery

| Check | Result |
|---|---|
| Signed profile binary SHA-256 | `8de690f13c6e6629e149fdc1e15198c6a8b6fad65d6b377650f8be065cfed4d5` |
| Built app size | 35.1 MB |
| Install | PASS — `flutter install --profile` exited 0 and replaced the previous local bundle |
| Device inventory | one `ZYRA`, `app.zyraconnect.zyra`, version `1.0.0`, build `2` |
| Launch | PASS — `devicectl` launched the bundle |

Because the same bundle was replaced, the superseded build's local app
sandbox/session was cleared. No Supabase/Apple account or server data was
deleted. TestFlight build 3 remains a separate older artifact and did not
receive this local source update.

## 5. Source true-pre/current ledger

| File | True pre SHA-256 | Current SHA-256 |
|---|---|---|
| `SOURCE/lib/widgets/zyra_onboarding_account_exit.dart` | NEW | `929245df71bbba2599bcdb26e746f4bfa1e1a9272a9dc62b2542862854923a8d` |
| `SOURCE/lib/services/zyra_auth.dart` | `98c6b2e38579a2f22ca97ba8a837c19c8fb071c4995bd7c07daa802ed13fa7ed` | `5588c910f2c12fa466db32c23661ae6035c85527e4fcac2924dc73986059ead0` |
| `SOURCE/lib/widgets/onboarding_scaffold.dart` | `9e0e9d99d44db6581ad08f9260446fb0f97ab7c75f99616b661f4a28ce5749f7` | `151a4901e5b01482160da8681dc988d9cebfd85d7dfc8814f2c871ae72583e61` |
| `SOURCE/lib/screens/auth/role_selection_screen.dart` | `f26d45d04b88181155dbf65df7b2b0bb4bc711c8606fdf71e2548b081982dab9` | `4bf29479209c38527cdf97f6c5e274b880bb44935de5bf02ba6b060acad15bb6` |
| `SOURCE/lib/screens/onboarding/onboarding_flow.dart` | `71f4e0577b1b7d779cf06018fb11b4aef30ac0418d5a79057672f130774c5e0f` | `2a9105714b60e9ea99e31eb3f4ae42a05297ead3ff4ed04cadef90056723dc58` |
| `SOURCE/lib/screens/onboarding/onboarding_stage_intro_screen.dart` | `15ddcae3233a2e6125d315bc71dd5ff1eac40eaa54ef11f12e90895e86be747` | `2c04905037f2690ee96ec83d28c3abf49452469c3f82fe21b2bc72482cf29ce9` |
| `SOURCE/lib/screens/onboarding/account_path_overview_screen.dart` | `94c3c4f1fa5a42f7cdcbdc53c176c56a8071e868785536002ebfb20c2b9c9412` | `bb8b441ec6df7a5082e7120ee49b9dc25f69dd3bb8e08fa9205f344dee4fff97` |
| `SOURCE/lib/screens/onboarding/identity_verification_screen.dart` | Not retained before edit; disclosed evidence gap | `afbc67f599c032aefb79653c39b0a2f09acf2c73407502ac364ec16684873c99` |
| `SOURCE/lib/screens/wali/wali_onboarding_flow.dart` | `9b3da21775e218919cdfd877cd623eed526de68112e51ea59ee90895e86be747` | `8473df1601c5db5eaef046dcd830f525d366f2b2ae1bd65c1c00b0f84c7acd50` |
| `SOURCE/test/zyra_signup_runtime_test.dart` | `81dfe6026e4965e6d8e0093852a6339b4d0882e702f6d989cb4f0f77d6908533` | `504bd61e3a402306a86ec79244094b86900ffc04ab65aef1a3ab0c41e72f7b2c` |
| `SOURCE/test/onboarding_account_exit_surface_test.dart` | NEW | `48395f870c3aa6a7ebb28f85ed86dee267c3a6a1724f32d5bbd5dffdbc0e4298` |
| `SOURCE/test/initial_identity_check_screen_test.dart` | Not retained before edit; disclosed evidence gap | `77edda12937986bd13814ffa4c52127d4ad4658530e837fba491b17515b6fdae` |
| `SOURCE/test/zyra_one_app_release_tooling_contract_test.dart` | `ea8c15364c8179ef4366d31bf1ba8d76a7773222236d408ef1f0b2b96ddcb8ac` | `a4de00c666865022ad81b308c8e48506aa979f8e16e1287e9e081ec21fa9c314` |

The two disclosed pre-hash gaps are not reconstructed and are not represented
as audit anchors. Current bytes, focused behavior and installed binary remain
directly verified.

## 6. Governance reconciliation

| File | True pre SHA-256 | Post SHA-256 |
|---|---|---|
| `SYSTEM/DOCUMENTS/ZYRA_INITIAL_SIGNUP_RECOVERY_HANDOVER_CURRENT_VERSION_V1.md` | `90e767d558ebb80b5700bd2583e4fdba244b21096f7e87efaa809bd24a47e048` | `baeaf5887a3afc176b8d72f026ef5f6926327c077d0d3227bd90bc5786ff5c2e` |
| `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` | `73e645261da483ce22606026c7fc10e44b47f600a133712ead77693c276bfad6` | `08da3ef48b8ec31c13299a4664524f0813e6527ffbf57a8a42f473cf4ad7c257` |
| `SYSTEM/DOCUMENTS/ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V4.md` | `b2e027d4eefa19064c9beeab19ceacf81833eec21bbcce53f533a477bc310b72` | `b0ee7f40d287416bb28786d78589178fa87212c354c74c08bb5e7d5bd02d87cf` |

This Message 132 had no pre-state. OA-ZYRA-286 remains open; no new OA
identifier was created and `NEXT IDENTIFIER` remains OA-ZYRA-290.

— END OF MESSAGE 132 —
