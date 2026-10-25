# 120 — CODEX → FOUNDER
# SUBJECT: EVERY ACTIVE GUARDIAN RECEIVES A NARROW JOURNEY SUMMARY — CLIENT INSTALLED; SERVER CHANGE STAGED ONLY
# DATE: 2026-09-17
# STATUS: CODEX INTERNALLY VERIFIED · LOCAL CLIENT INSTALLED · MIGRATION NOT APPLIED
# GOVERNANCE: DR-ZYRA-230 · OA-ZYRA-288 · direct Founder instruction 2026-09-17

## 1 · Outcome

The screenshot was not a random copy defect. It accurately exposed the former
DR-ZYRA-224/225 rule that Additional Guardians received no Journey information.
The Founder replaced that rule directly.

The local app now:

1. removes every user-visible claim that an Additional Guardian receives no
   Journey information;
2. shows the server-confirmed four-field Journey-summary module in both Main
   and Additional Guardian workspaces;
3. gives developer Additional-Guardian previews a truthful sample summary;
4. keeps rich current context, counterpart details, full Journey routing,
   Family Review and Guardian Gate decisions Main-only; and
5. retains truthful loading, empty, failed and last-known states.

The server replacement is staged only. No live database changed.

## 2 · Safety interpretation

"All Guardians have Journey information" is implemented as the least-privilege
extension of the existing server summary:

- current active/paused attempt summary for every current active Guardian;
- ended summaries from that Guardian's own current continuous active-link
  period;
- the existing bound full-history consent remains current-Main-only; and
- the response remains attempt_id, started_at, ended_at and ended only.

No counterpart identity, Journey stage, messages, compatibility answers, end
reason, notes, reflections or safety data is added. A summary row never grants
a wider route or action.

## 3 · Staged migration

`SOURCE/supabase/migrations/20260917133709_guardian_journey_summary_for_all_active_guardians.sql`

SHA-256:
`886b3e0ff17b968f8575a976c32d338ee43a3c7e0372f5a491da6951c70b6c9c`

It replaces one function only, preserves the four-field signature, derives the
caller from auth.uid(), requires the caller's active link to the requested
Seeker, uses a positive active/ended allowlist, preserves Main-only bound
full-history consent, keeps `SECURITY DEFINER` with `search_path=''`, qualifies
all relations and explicitly denies PUBLIC/anon execution.

The file says STAGED ONLY. It was not applied, replayed against production or
sent to Supabase.

## 4 · Verification

- 36 focused Guardian UI, roster, developer-control and staged-SQL contract
  tests passed.
- Analyzer: 12 changed Dart/test files, no issues.
- iOS profile build: succeeded, 34.6 MB.
- Local iPhone install: `flutter install --profile` exit 0.
- No approved visual baseline was edited or regenerated.
- No cloud mutation, TestFlight upload or git operation occurred.

Official Supabase guidance was rechecked before staging: SECURITY DEFINER
functions keep an empty search_path with qualified relations and function
execution is explicitly revoked/regranted. The September 2026 breaking-change
index contains no change affecting this replacement.

## 5 · True pre-state and post-state ledger

| File | True pre SHA-256 | Post SHA-256 |
|---|---|---|
| `lib/screens/wali/seeker_guardian_designs.dart` | `21767b654235c3b19be2b0f29bc97a35a17765595601256c1ba37f9be1716d54` | `3d6488a942c09d76a810c6bdc45c42f1e57fd367248455b4e424b97e0447b8ed` |
| `lib/screens/wali/guardian_detail_screen.dart` | `b16b231091de6f481e79bf97b14b2e0d9294facf1bf12e52c802a86fd15a8820` | `6d034a39fd99618c0772ee78ecd673f53592b4cb8bbb561772d0088c4728b89e` |
| `lib/screens/wali/wali_seeker_workspace_screen.dart` | `d13d266ec3207b96aa8a2565c284e138234967607c06470497122afd89404a6a` | `0c8958644b933b62c304d20491acc509fbd5fc07ab35139ed96dd1e736c62978` |
| `lib/screens/wali/wali_seekers_screen.dart` | `6a5f27ae5f11f53b213e9b30956b50561bb2a6e349d6d98f7be416e539646194` | `4f5f40f84c40b960287d2789910088bfc4904f2c181004a7c837163557d8f148` |
| `lib/services/zyra_guardian_seeker_roster_resolver.dart` | `821bc1e767a1ef19874ff623054eaedcb92ed3ec2c671c3e7a076ae1074ecdb5` | `d8dceb8cd8689e68c766549883cc81143cc9d445bc900f7bfd3a930f45bcc0aa` |
| `lib/services/zyra_wali_journey_service.dart` | `32e0d6c5f51c5d09bab7d78b132e0f3a10c29b9da4e0aaf398f3cc3e5d3a2bdf` | `487f9070852774ebe48b9c1912de83a426171adaa4ac557df570e0135f1fe031` |
| `lib/dev/zyra_dev_scenario.dart` | `af722414506ab77e11d968963ba1d32f30f45d66e92ec7dc3aed431d7b21be12` | `80c316d483a9a59a668ca5274567d7ec6e52590ba0ac0e5074a134196b9b079b` |
| `lib/dev/wali_dashboard_preview.dart` | `3ccb629f8578197bb0f29b43080d69386ed980de046c6221345165956940e281` | `7a0002ad17dfd3e9474ef9643855772dea3eb384000d16cfc2383f1c4c52959f` |
| `lib/dev/wali_dev_scenario_panel.dart` | `0f2e09c67d4a9f953180db6726233ca2b8555bb2ea87d8a2224d45541e985435` | `24583dce4f311be74ad46d67532d8628da8af150ba3edaa7fc9e00406c3c42e6` |
| `test/guardian_seeker_workspace_test.dart` | `fba74b5cc790a17b25f27023c97d516ca72794c13d739ca5140694ac195a5232` | `743195b7934f413e0fbfd7612e958d07935936d438084fb2d82df63d50dec81d` |
| `test/wali_seekers_screen_truth_test.dart` | `39e91c15ef9cbaa6ebaa798fcae37a24917b54bfd9e56401cd6f0af0a36805c4` | `9667c2fed8ff1eba7449fbd59b943ddd08189a4d9416667a53206442eb62fdea` |
| `test/zyra_all_guardians_journey_summary_migration_test.dart` | ABSENT | `0f7adf0bd152616e7dcc424c3138c9d46baeac0e863cbe211c6a033ebed2b3b7` |
| `supabase/migrations/20260917133709_guardian_journey_summary_for_all_active_guardians.sql` | ABSENT | `886b3e0ff17b968f8575a976c32d338ee43a3c7e0372f5a491da6951c70b6c9c` |
| `SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md` | `60e5c15c09ff67f1f91c64ef979e8969b507bc3b65b35a35ce008cda760049e4` | `7466900bbef633fce50941bc094e6f45e6d2f42d8aac121706c51d3588ca99b4` |
| `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` | `a0b24071e5e1a24c1dae8ca1702f035a51ecbeaaf26d12dd1653a43362d68c98` | `ac6ef0c7ae98102ed9739e1efb6e02b1161d770ac668c579ccbc1770955699ba` |

True pre-files are preserved under
`/private/tmp/zyra-guardian-journey-access-pre-20260917/`. New files are
recorded as ABSENT, not reconstructed.

## 6 · Remaining gate

The local UI is ready for Founder inspection. Making Additional-Guardian
summary access live still requires a separate exact-file apply GO for the
migration hash in §3, followed by direct-call post-apply verification for:
unauthenticated, unrelated, Seeker, active Main, active Additional, removed,
inactive, current, ended-in-period, pre-link-ended and Main-consent cases.

