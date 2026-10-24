# 133 — CODEX → FOUNDER — Demo Personal Codes; iPhone Updated

**Date:** 2026-09-17  
**Programme:** OA-ZYRA-286 / OA-ZYRA-289  
**Authority:** Founder's direct instruction to build, with the explicit rule
that demo profiles must never reach the real market

## 1. Outcome

The sole ZYRA app now shows a stable demo-only ZYRA Code for each Founder
preview persona:

- Adam — `ZYRA-DEMO-SEEKER-ADAM`
- Maryam — `ZYRA-DEMO-SEEKER-MARYAM`
- Ibrahim — `ZYRA-DEMO-GUARDIAN-IBRAHIM`
- Khadija — `ZYRA-DEMO-GUARDIAN-KHADIJA`

The prior “Your ZYRA Code couldn't be refreshed” state is removed in this
Founder-preview context. Copy, QR and Share remain reviewable. Rotation is
hidden because these fixtures are intentionally fixed.

## 2. Market and data boundary

This is not a fake production account and no demo identity was written to the
database. The branch requires both:

1. `ZyraInternalPreviewClient.isActive`; and
2. `ZyraDeveloperAccess.isMainAppFounderPreview`.

The compile capability remains default-OFF. The demo strings use a namespace
that deliberately fails the live personal-code parser, so they cannot be
stored or resolved by the production service. The existing preview client
continues to deny all non-auth Supabase traffic. Real accounts still use the
live IDV-gated OA-ZYRA-289 RPC and schema without alteration.

No Supabase change, migration, production write, TestFlight upload, App Store
change or git operation occurred.

## 3. Verification

- deterministic fixture and live-format rejection tests: PASS;
- rendered Founder-preview screen test: PASS — demo code shown, refresh error
  absent, preview warning present, rotation absent;
- preview-client denial plus release-boundary suites: PASS;
- focused total: 28/28 PASS;
- whole-tree `flutter analyze`: PASS, no issues;
- signed iOS profile build: PASS, 35.1 MB;
- install inventory: exactly one ZYRA app, bundle `app.zyraconnect.zyra`,
  version `1.0.0`, build `2`;
- device launch: PASS.

Built executable SHA-256:
`3ab53e2e675c9c3e1f16a5ef184c0bcc2717d6b08aff88f666eaa863f5010fe1`.

## 4. True pre-state and output ledger

| File | Pre SHA-256 | Post SHA-256 |
|---|---|---|
| `SOURCE/lib/screens/wali/zyra_code_screen.dart` | `fcb79de2815509629dd71d0f4e1c2c5cb4e7c08ba4d2a588da287c2336a201b3` | `7d24899f3516d399e463d2c60ccd2993bcd3de3da78f2fe291a6a4cbba334a5f` |
| `SOURCE/test/zyra_one_app_release_tooling_contract_test.dart` | `a4de00c666865022ad81b308c8e48506aa979f8e16e1287e9e081ec21fa9c314` | `a5f158027e0848b8604e64e58324e61e757e38118711f1e6bda78761994ea0ec` |
| `SOURCE/lib/dev/zyra_dev_personal_code_fixtures.dart` | NEW | `6d48b3aa6de42b66d6211277f4fef7a3996b73b0d4b1b179e02e48e9c2e5bb66` |
| `SOURCE/test/zyra_dev_personal_code_fixtures_test.dart` | NEW | `f887542891e8d25c5611eae731927af5f7da888ec08b5d9b7c91c3d94be114ab` |

The governance-document pre-hashes were captured at edit time:

- Outstanding Actions: `08da3ef48b8ec31c13299a4664524f0813e6527ffbf57a8a42f473cf4ad7c257`
- personal-code handover: `ab23e0f4cd0a21d981c9e4ee8ab19a0e55550cde7d9554026ffbb16961b38d4f`
- developer-control handover: `320a606f260e5aa1c1fb525257ffe5110ecaf103bdd09ca707d78c9534460e63`
- Guardian relationship source: `474f4ae3652b3ae97ab5499c0b373ed88426ca10abbb5ac23edc8ffd9088eec9`

## 5. Founder check

Open Developer Access, choose a Seeker or Guardian, and open Add Guardian/Add
Seeker. The persona's fixed demo code should render immediately with no refresh
error. Founder visual acceptance remains separate from this engineering pass.
