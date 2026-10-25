# 023 — CODEX → FABLE — 2026-08-29 — OA-ZYRA-277 SETTINGS COPY COMPLETE

## 1. Status and authority

**Authority:** DR-ZYRA-219 items 1, 4 and 5 · OA-ZYRA-277 ·
`022_FABLE-CODEX_2026-08-29_DR-219_RULING_AND_SETTINGS_COPY_GO.md` · direct
Founder relay 2026-08-29.

**Verdict:** the Sign-in & Security screen is **CODE COMPLETE and
regression-verified** for the authorised V1 copy correction. It now describes
only the sign-in methods already attached to the current account and no longer
offers or promises “Add Apple/Google”. Manual identity linking remains OFF.

Fable verification and Founder device acceptance are **PENDING**. The
Google/Apple collision matrix is also **PENDING** until a real Apple identity
exists after OA-ZYRA-274 / App Store Runbook Phase 2; no result is inferred or
mocked here.

No auth setting, Supabase project, server, schema, migration, identity,
production row, unlink flow or git state was changed.

## 2. What changed

| Surface | Before | Live source after |
|---|---|---|
| Screen introduction | “Your ways into ZYRA” and a promise to connect a backup | “How you sign in” and an informational explanation of currently connected methods |
| Provider list | Apple and Google always rendered; absent provider said “Not connected” and exposed `Add` | Only attached Apple/Google identities render, in deterministic Apple → Google order |
| Provider controls | Missing methods invoked manual linking | Current-method cards are informational and display `Connected`; no provider action exists |
| Seeded email-only account | Apple/Google appeared unavailable alongside test-account copy | One truthful, non-actionable `Email sign-in` method is shown for the existing seeded identity |
| Recovery email | Separate recovery card and one-time-code flow | Unchanged |

The recovery card may still say `Add` when no recovery email exists. That is
intentional and is not a provider-linking promise.

## 3. Data flow and architecture boundary

```text
Supabase server-authoritative authenticated user
  -> ZyraAuth.linkedProviders / providerEmail / recoveryEmail
  -> SignInSecurityScreen reads current identities
  -> attached sign-in methods render as information
  -> recovery remains a separate authenticated one-time-code flow
```

No current-method card performs a write or calls an OAuth SDK. The dormant
future plumbing remains in `ZyraAuth` for a separately authorised enablement:

- `linkGoogleIdentity()` remains at line 256;
- `linkAppleIdentity()` remains at line 298; and
- `_mapLinkError()` remains at line 611.

The `SOURCE/lib/services/zyra_auth.dart` SHA-256 is still exactly the hash
reported in 019, proving that OA-ZYRA-277 did not alter auth behaviour:
`0343dcd0255c1abe2dcbbd05c08663ce44a30897175280c80767d7615e125699`.

No client inference or email-based identity merge was introduced. DR-ZYRA-219
remains the authority for the permanent server-authority principle; this UI
does not encode the present provider/configuration behaviour as an eternal
invariant.

## 4. Files and hashes

| File | Responsibility | SHA-256 |
|---|---|---|
| `SOURCE/lib/screens/settings/sign_in_security_screen.dart` | Informational current-method presentation; recovery flow retained | `b7054c104f9cd472c99691c67e2e1be38e4cf71b2f1d5b05e8b132d79df082b2` |
| `SOURCE/test/sign_in_security_screen_test.dart` | Google-only, already-linked Apple+Google, and seeded email-only UI contracts | `86c5dbd84e22ea0e7af3909b6ef3939c2effb6611cd5356f7db29d7b2b89e5cb` |

This handover's own hash is reported after writing to avoid a self-referential
hash.

**Migrations changed/applied:** none.

## 5. Tests and measured evidence

| Measurement | Result |
|---|---|
| `dart format lib/screens/settings/sign_in_security_screen.dart test/sign_in_security_screen_test.dart` | PASS — both files formatted |
| `flutter test test/sign_in_security_screen_test.dart` | PASS — 3/3 |
| `flutter test test/email_recovery_screen_test.dart test/sign_in_security_screen_test.dart` | PASS — 8/8; provider presentation plus existing recovery/welcome coverage |
| Full `flutter test` | PASS — 619/619 |
| `flutter analyze` | PASS — no issues |
| `python3 tools/zyra_check.py` | PASS — 173 files, 0 findings; 5 baselined dangling-document references and 0 new |
| Google-only fixture | Google shown; Apple and `Not connected` absent; no provider `TextButton` |
| Apple+Google fixture | Both attached methods shown, Apple then Google; neither exposes an action |
| Seeded email-only fixture | Existing email method shown; Apple/Google absent; no provider action |
| Real Apple/Google collision matrix | **PENDING** — deliberately blocked on OA-ZYRA-274 / Phase 2 real Apple identity |
| Founder physical-device copy review | **PENDING** |

The new widget tests use an in-memory test Supabase session only. They do not
contact or modify the live Supabase project and cannot grant a production
identity.

## 6. Mock versus production

- The copy and conditional provider rendering are live production Flutter
  source.
- Provider identity data remains server-originated through the authenticated
  Supabase session.
- The email-only state exists for current seeded developer personas; it does
  not add public email sign-up or a third public OAuth option.
- The tests stage identity arrays locally and verify presentation only. They
  do not claim provider, collision or manual-linking integration evidence.

## 7. Retained limitations and documentation reconciliation

1. Manual linking remains OFF and there is no unlink UI, as DR-ZYRA-219
   requires.
2. Collision-matrix integration evidence remains pending exactly as directed.
3. The capability matrix in DR-ZYRA-219 item 8 remains definition work under
   OA-ZYRA-266; no capability gating was added.
4. `APP/Settings/SUMMARY.md` and
   `SYSTEM/DOCUMENTS/ZYRA_SETTINGS_AND_IDENTITY_CURRENT_VERSION_V2.md` still
   describe the earlier manual-linking model. DR-ZYRA-219 supersedes those
   sentences. Fable should reconcile the governed copies during verification;
   Codex did not widen OA-ZYRA-277 into a Documentation Office edit.

## 8. Verification request

Fable: please verify the two live-file hashes, re-run the focused tests, confirm
that the provider cards have no linking action, reconcile the two superseded
documentation passages named in §7, and update OA-ZYRA-277 truthfully. Founder
device acceptance remains the final UI gate.

— END —
