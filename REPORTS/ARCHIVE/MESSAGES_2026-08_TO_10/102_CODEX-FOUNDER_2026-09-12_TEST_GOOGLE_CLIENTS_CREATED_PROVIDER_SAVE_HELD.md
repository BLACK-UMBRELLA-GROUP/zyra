# 102 — Test Google clients created; provider save held

TO: Founder
FROM: Codex — Operations / Governance / Delivery
DATE: 2026-09-12
OWNER: OA-ZYRA-286
STATE: PARTIALLY EXECUTED / CLIENTS POST-VERIFIED / SECRET TRANSFER HANDOFF

## 1. Outcome and authority

Two separate Test Google OAuth clients were created exactly once. Their
public identity/configuration was read back successfully. Google sign-in is
**not enabled in Test Supabase**: the attempted confidential secret-field
entry did not persist, the equality check failed, and no provider Save was
attempted. No automated repair or retry followed. Founder handoff is pending.

Founder gave `OK PROCEED` for the exact bounded Test Google action, then
completed Supabase company login and instructed continuation. The exact
action file remains byte-identical:

`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/evidence/oa286-google-signin-action-v1.md`

SHA-256: `63e9a72928099537e0d0995bee71d2352ea0d62c5b36e237cbb30f85bcfc1110`.

This is not a new credential, provider, account, migration or upload approval.
The two creation authorities are consumed. The one provider-save allowance
has not been exercised. The contract explicitly permits Founder handoff if
confidential transfer cannot be completed; do not infer an automated retry.

## 2. Fresh pre-state and exact targets

Company Chrome showed Google account `admin@zyraconnect.app`, project
`zyra-app-506315` / ZYRA App / number `734578322486`. Immediately before
creation, exactly the three existing clients were listed; neither Test name
existed. No existing client secret was opened or read.

Test destination was authenticated company Supabase, project
`xqweloifosbwfgctzros` / ZYRA Test, organisation `pdekarsldtaqlqdthgwh`.
Google provider was disabled; Client IDs and secret blank; nonce-skip OFF;
email-less users OFF. Email was Enabled, Apple Disabled, signup and
confirm-email ON, manual linking and anonymous sign-in OFF.

## 3. Created identities and observed configuration

| Name | Type | Public OAuth client ID |
|---|---|---|
| ZYRA Test iOS | iOS | `734578322486-lk30rpiog0gh01f679qvmpgen8a0jak8.apps.googleusercontent.com` |
| ZYRA Test Supabase Web | Web application | `734578322486-k3v6akqgv55pv3ukgj521lh7ebokja6r.apps.googleusercontent.com` |

iOS readback: bundle `app.zyraconnect.zyra.test`, Team `9Y7Z8F36SJ`, App Store
ID blank, Firebase App Check OFF. Google displayed creation time
12 September 2026, 16:01:36 GMT+1. Native URL scheme shown:
`com.googleusercontent.apps.734578322486-lk30rpiog0gh01f679qvmpgen8a0jak8`.

Web readback: no JavaScript origins; exactly one redirect URI:
`https://xqweloifosbwfgctzros.supabase.co/auth/v1/callback`.
Both IDs differ from the existing Production identities.

The post-inventory lists five clients. The original three remain with the
same names, types and IDs:

- ZYRA Android:
  `734578322486-1o7jvjl39cnhaqm30akdn9kg8ph89kgs.apps.googleusercontent.com`
- ZYRA iOS:
  `734578322486-eoh5ba4usl0svs9ihqh2ltagqfgusnft.apps.googleusercontent.com`
- ZYRA Supabase Web:
  `734578322486-gvi63m04ogd7bbmsunokuq2klkepetq1.apps.googleusercontent.com`

This is inventory preservation evidence, not a test of existing sign-in or
an audit of unread existing-client settings.

## 4. Shared-domain side effect survives the partial stop

Google automatically added the approved Test authorised domain
`xqweloifosbwfgctzros.supabase.co`. The existing Production domain
`sxoaxonzjqkgajmlagyk.supabase.co` remains. No manual Branding Save occurred.
Readback shows exactly these two domains, ZYRA app name, company support and
developer contact, blank homepage/privacy/terms fields, no selected logo,
and disabled Save/Discard controls. Audience remains External / Testing with
the sole listed test user `admin@zyraconnect.app` (1 test / 0 other).
No audience, publishing, scopes, tester-list or billing mutation was made.

The earlier incomplete-branding and aggregate secure-flows findings remain
open. This configuration work neither diagnoses nor resolves those findings.

## 5. Secret-transfer stop and persisted provider truth

Only the newly generated Web secret was read, into transient browser-tool
memory through a non-emitting creation-panel read. One secret-field entry
returned without a tool error, but the subsequent source/destination equality
result was FALSE. Read-only inspection found an INPUT of type password with
an empty value and no value attribute. The same value inspection correctly
read the populated public Client IDs field. The reason the attempted entry
did not persist is unestablished; do not blame Supabase or claim a credential
validity failure without evidence.

No Save was clicked. No second automated entry, recreation, rotation,
deletion, rollback, clipboard operation or credential download occurred.
Secret and raw-panel variables were cleared in finally; this is not a claim
of physical RAM erasure. No secret appears in source, evidence, screenshots,
chat or a local credential file. The one-time Google panel remains open for
the explicit Founder handoff.

The unsaved form contains Google ON, the exact new Web ID first then iOS ID,
nonce-skip ON, email-less OFF, and a blank secret. These are **draft controls,
not saved provider state**. A separate newly loaded provider list confirms
Google and Apple Disabled, Email Enabled, signup/confirm-email ON and
manual-linking/anonymous OFF. No live Auth sign-in, user creation or role
assignment occurred. Session/URL settings were outside the action and were
not inventoried; no measured before/after equality is claimed for those pages.

## 6. Founder handoff and next verification

Founder was asked to enter the same newly generated secret from Google's
one-time creation panel into the held Test Supabase Client Secret field,
never into chat, and not to click Save yet. Await that response. Reconfirm
the exact project and perform confidential equality verification before the
remaining single provider Save. Do not recreate either Test client, generate
another secret, or treat the failed automated field entry as authorisation
for another automated attempt.

Held company-Chrome tabs: Google creation panel `624662664`; Test Supabase
unsaved provider dialog `624662659`. Both marked for handoff. The independent
read-only audit tab is not retained. Do not export/screenshot the secret
panel or ask Founder to paste its secret into chat.

Even successful provider Save will prove configuration only. Actual sign-in,
Founder UUID creation, protected-role assignment, exact approved resource
pins, local values, full schema replay, Edge/IDV/persona provisioning, Apple
Test identity/signing/upload and device acceptance remain separately gated.
Production ZYRA/TestFlight and production Supabase were not changed.

## 7. Local evidence, true pre-state and validation

Workspace root:
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3`

| Artifact relative to workspace | Pre-state / SHA-256 | Post SHA-256 |
|---|---|---|
| `evidence/oa286-google-signin-action-v1.md` | `63e9a72928099537e0d0995bee71d2352ea0d62c5b36e237cbb30f85bcfc1110` | unchanged |
| `evidence/oa286-google-signin-action-v1-status.md` | `2ea9c5d4c1341da251264792895bf5e536641cf971cf2077cc34b9015cc5899d` | `2c7222713ad34eef2e9704d721e87e81d2ed1e682bcda6df80bc9c2ba16d563f` |

True pre-edit copy of the status file:
`evidence/oa286-google-partial-prestate-v1/oa286-google-signin-action-v1-status.md`.
Its hash matched the source immediately before editing. Historical login-hold
text was retained under an explicit historical heading, not silently erased.
This numbered report's true pre-file state was ABSENT, checked before creation.

Validation: both creation success panels, five-client inventory, Test iOS and
Web public detail readbacks, shared Branding and audience readbacks, failed
confidential equality, safe field metadata and independently loaded saved
provider list. No application code changed; no Flutter tests, analyzer, VM,
container, SQL, cloud API, Apple action or git command was run for this step.

This report supersedes 101's pre-creation inventory and login hold, but does
not close OA-286. The master OA and living auth/runbook/handover prose have
not yet been reconciled for this partial checkpoint; their earlier statements
that Test clients were uncreated describe the prior state, not permission to
create duplicates. Reconcile them at the next bounded continuation, preserving
this partial-result evidence. All runtime pins remain deliberately unassigned.
