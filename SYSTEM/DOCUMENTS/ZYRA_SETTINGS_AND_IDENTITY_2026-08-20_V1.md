# ZYRA — Settings & Identity

**Status:** SUPERSEDED 2026-08-20 by ZYRA_SETTINGS_AND_IDENTITY V2
**Version:** V1 · **Source of truth** for Settings scope and identity mutability
**Amended:** 2026-08-07 — Identity Principles added, Identity Correction
process approved, `first_name` validation built. Amended in place rather
than versioned: V1 was created and ratified in the same session and has
not yet been referenced by other work.

**Supersedes** (now reference-only, decisions below take precedence):

- `ZYRA_SETTINGS_ROUND2_FOR_REVIEW_2026-08-07.md`
- `ZYRA_IDENTITY_AND_SIGNIN_FOR_REVIEW_2026-08-07.md`

---

## 1. Identity Principles

**The reference point for all future work on identity.** Anything that
appears to require an exception is a mis-framing until proven otherwise —
and the exception that looked reasonable is exactly how the un-publish
loophole came to exist.

1. **Identity becomes trusted at first publication.** Before publication it
   is a draft and freely correctable. After it, other people have started
   relying on it.
2. **Publication state and identity state are independent.** They are
   different questions with different lifetimes, and collapsing them into
   one column is what created the loophole.
3. **A user may always withdraw their profile.** Unconditionally, without
   asking, at any time. Nobody needs permission to leave.
4. **Withdrawal never reopens identity.** Leaving is a right. It is not a
   route to becoming someone else.
5. **Corrections go through the correction process** — never by bypassing
   an architectural rule, and never by making a frozen field editable
   "just this once".

**A sixth, implied by all of them and worth stating:** *every write path
must enforce the same rules.* A rule that lives in one function and not on
the table is a rule that applies to whoever happens to use that function.

---

## 2. Where the Founder overrode the review

Five changes. All are recorded because in each case the review was weaker
than the decision, and the reasoning matters more than the outcome.

| # | Review said | Founder decided | Why it is better |
|---|---|---|---|
| 1 | Ask for notification permission at the first **match** | At the first **Journey** | A match is a possibility. A Journey is a commitment with another family in it, and the first point where a missed notification costs someone something. Asking earlier spends the one prompt we get on a moment the user has no stake in. |
| 2 | "Start again" | **"Reset profile"** | "Start again" reads as deletion, which is the opposite of what it does. |
| 3 | Close the un-publish route **or** keep it open deliberately | **Close it** | "Otherwise the freeze becomes a policy that can be bypassed rather than an actual rule." |
| 4 | App lock is cheap and worth building | **Flagship privacy feature** | "Protect your ZYRA account with Face ID" is a reason to choose ZYRA, not a checkbox. Positioning changes what gets built and how it is described. |
| 5 | DOB corrections are "a support case" | **A defined Identity Correction process** — §4 | "A support case" is not a design. It names who does it and leaves everything else undecided, which is how a compliance obligation quietly becomes nobody's job. |

---

## 3. Approved decisions

### Settings

| Item | Decision | State |
|---|---|---|
| **Notifications** | Two axes: OS permission (theirs) and our five categories (ours). Permission requested at **the first Journey**, never at launch. Apple 4.5.4 — no feature may be gated behind granting it. | Queued |
| **Language** | **Defer.** No picker until a second language exists. Decide target languages early: **Arabic and Urdu are right-to-left**, a layout change on every screen. | Deferred |
| **Restore Purchases** | **Required** by Apple 3.1.1. Ships as part of the payments feature, not as a Settings row. Cannot be built before IAP — there are no receipts to restore. | Blocked on IAP |
| **App Lock** | **Build.** Flagship. | **Built** |
| **Contact blocking** | **Defer.** Do not read the address book for v1. Reference-code blocking first (OA-160). If revisited, a dedicated privacy project with a DPIA, not a settings toggle. | Deferred |
| **Manage Account** | Five exits: Take a break · **Reset profile** · I'm getting married · Delete profile · Delete account. | Queued |

### Identity

| Field | Rule | Enforced by |
|---|---|---|
| **First name** | **Editable, permanently.** Marriage, deed poll, spelling and cultural reasons are all ordinary. Trimmed and length-limited on every write path. | Column grant + `profiles_first_name_shape` + trim trigger |
| **Surname line, bio** | Editable. **No agreed limit yet** — §8 | Column grant |
| **Date of birth** | **Frozen at first publication.** Correction via §4 only. | No column grant + `first_published_at` |
| **Gender** | **Frozen at first publication, permanently.** Correction via §4, and approval should be rare — a change here rewrites who the person can see and be seen by, and leaves any live Journey standing in a state the product forbids. | No column grant + `first_published_at` |
| **Role** | Never flips | RPC |

**Name-change history: deliberately NOT built.** Founder ruling — an audit
log becomes valuable once identity verification exists, because at that
point changing a *verified* name has consequences. Until then it is
surveillance of an ordinary act on a platform whose users are already
nervous about being seen. Revisit with verification, not before.

### Sign-in

- Show the **provider** and the **email address**, always.
- Show the **Apple relay explanation only when the address is a relay**.
- State plainly that ZYRA has **no password and cannot change the email**.
- State plainly that **there is no account recovery**. Do not invent one.
- **Fix the provider fallback** so a misconfiguration is obvious to a
  developer instead of reading as a design choice.

---

## 4. The Identity Correction process — APPROVED, not yet built

**Users never edit a frozen field themselves.** Not once, not with a
warning, not behind a confirmation. The correction is a separate process
with a human in it, which is what makes the architectural rule survivable.

| Step | |
|---|---|
| 1 | User requests an identity correction |
| 2 | Selects the field — date of birth, gender |
| 3 | Gives the reason |
| 4 | Support reviews |
| 5 | If approved, an **admin-only** process updates the value |

**Why this is the right shape.** It satisfies **UK GDPR Article 16**
(rectification without undue delay) without putting a frozen field behind
a form. It keeps the freeze absolute at every client path — which is what
makes it a rule rather than a default. And it puts a person between "I
typed the wrong year" and "I am changing who I am", which is the only
place that distinction can actually be drawn.

### The blocker, stated plainly

**There is no admin.** `profiles.role` permits `'admin'`, but
`zyra_create_profile` refuses it by design — *"If an admin role is ever
needed it will be granted by an operator, never claimed by a client."*
Nothing reads it, no tooling exists, and no RLS policy grants an admin
anything.

So step 5 has no owner. **Building steps 1–4 without it would produce a
queue nobody can action** — which is worse than no queue, because the user
has been told their request is being reviewed.

### What must be decided before this is built

| Question | Why it blocks |
|---|---|
| **Who is "support"?** A ZYRA admin role, or an operator working directly against the database? | Determines whether this is a product feature or a runbook |
| **What evidence is required?** Nothing, a stated reason, or a document? | A DOB correction with no evidence is an editable DOB with extra steps — and DOB is the field an underage user would change |
| **What is the user told, and when?** | An unanswered request is worse than a refusal |
| **Is a correction reversible, and is it recorded?** | A correction that leaves no trace is indistinguishable from the loophole that was just closed |

**The evidence question is the one that decides whether this works.** Every
other part follows from it.

---

## 5. What is built

### 5.1 Migration `freeze_identity_on_first_publication`

`profiles.first_published_at timestamptz`, written once by
`zyra_set_profile_complete()` and **never cleared**, including on
un-publish. `zyra_create_profile()` tests that column instead of the
reversible `profile_complete`.

This is Principle 2 made physical: `profile_complete` is a publication
switch the user is entitled to turn off, which is exactly why the freeze
leaked through it.

**Verified end-to-end against a real published Seeker, then rolled back:**

| Check | Result |
|---|---|
| Un-publish still works, unconditionally | ✅ `{"status":"unpublished"}` |
| Re-running onboarding after un-publishing | ✅ `{"status":"name_only","reason":"identity_frozen"}` |
| Gender after the attempt | ✅ unchanged |
| Date of birth after the attempt | ✅ unchanged |
| Name still editable | ✅ changed |
| Marker survived un-publication | ✅ |

**Also verified:** 144 published rows backfilled, 0 published rows
unmarked, 0 unpublished rows wrongly marked, function grants preserved
across `CREATE OR REPLACE`, and `first_published_at` readable but **not
writable** by any client.

The backfill ran with the `profiles_updated_at` trigger disabled —
otherwise marking 144 rows would have rewritten `updated_at` on every one
and destroyed the only "last changed" signal the table has. Confirmed
afterwards: **0 rows touched.**

### 5.2 Migration `profiles_first_name_shape`

Principle 6. The 60-character check lived in `zyra_create_profile`, which
is **not** the path the app uses — name edits go through the column grant,
where there was no constraint, no trim and no character rule. A
4,000-character name was accepted and would render on a Browse card.

- **Trim in a BEFORE trigger**, so `"  Sara  "` becomes `Sara` rather than
  an error.
- **Length in a CHECK**, 1–60. The "is trimmed" half is redundant in normal
  operation and kept deliberately: the previous migration disabled a
  trigger on this same table, and if that happens again the constraint
  still holds. It fails closed.
- **`char_length`, not `octet_length`** — so an Arabic, Urdu or Bengali
  name gets the same 60 as an English one. Byte-counting would have given
  multi-byte scripts roughly a third of the allowance, on an app whose
  users disproportionately have exactly those names.

**Verified on the column-grant path, then rolled back:**

| Check | Result |
|---|---|
| `'   Sara   '` | ✅ stored as `'Sara'` |
| 4,000-character name | ✅ rejected by `profiles_first_name_shape` |
| Whitespace-only name | ✅ rejected |
| 60 Arabic characters | ✅ accepted, `char_length` 60 |
| Gender on the same path | ✅ still refused, no grant |

Data checked before applying: of 149 rows, 0 untrimmed, 0 empty after
trimming, 0 over 60. Longest existing name is 8 characters. Nothing was
rewritten.

### 5.3 Sign-in & security

`lib/screens/settings/settings_screen.dart`

The fallback that read **"Signed in with Your provider"** is gone. It
concealed a real fact: all **149** accounts have `provider = 'email'` —
seeded test accounts through the password provider, still enabled
server-side. **No Google or Apple identity has ever been created**, so that
string had been showing for the panel's entire life while looking
deliberate.

Now `Test account` / `NOT SET` outside release, plus a dev-only warning
block in the dialog. Release builds stay clean. The dialog gained the Apple
relay explanation (only for `@privaterelay.appleid.com`), the "cannot
change your email" line, and the recovery statement.

### 5.4 App Lock

| File | Role |
|---|---|
| `lib/services/zyra_app_lock.dart` | State, authentication, lifecycle policy |
| `lib/widgets/zyra_app_lock_gate.dart` | Wraps the whole app above the navigator |
| `lib/screens/settings/app_lock_screen.dart` | One toggle and honest copy |
| `lib/services/zyra_local_prefs.dart` | The preference, read before first frame |
| `lib/main.dart` | `hydrate()` before `runApp`, gate as outermost wrapper |
| `pubspec.yaml` · `MainActivity.kt` · `AndroidManifest.xml` · `Info.plist` | `local_auth` and native config |

**No PIN — a change from the review, and the Founder's preferred design.**
Our own PIN would have to be stored, and the only local store is
SharedPreferences, which is plain text. `biometricOnly: false` falls back
to **the device's own passcode**: stronger than four digits we invent,
works on devices with no biometric hardware, and **ZYRA stores no secret at
all.** Nothing here for an attacker to extract.

**Neutral gradient on the lock screen, not the gender gradient.** Whoever
is holding the phone sees this screen; pink or blue would disclose whose
account it is before anyone authenticated.

**Three states, not two.** `paused`/`hidden` locks. `inactive` only
**obscures** — because `inactive` also fires for the Face ID sheet itself,
and re-locking there makes the unlock cancel its own unlock. Obscuring is
also what stops the iOS app-switcher snapshot showing someone's
Connections to whoever swipes up next. Invisible in normal use, therefore
easy to delete later by mistake.

**An escape hatch, deliberately.** The lock screen always offers *Sign out
instead*. This is **not a security boundary** — RLS and the session token
are — so being permanently unable to open your own account because a sensor
broke would be absurd. Nothing is lost: the account lives on the server.

`ZyraAuth.signOut()` calls `ZyraAppLock.instance.clearForSignOut()`
alongside the existing `clearForSignOut` calls, so the lock comes down from
**every** route out, not only the lock screen's own button.

---

## 6. Before this runs

```
flutter pub get      # local_auth is new
flutter clean        # native config changed on both platforms
```

Then a **device** build. App Lock cannot be tested in a simulator without
enrolled biometrics, and both native changes compile fine and fail on
hardware:

- **Android** — `MainActivity` now extends `FlutterFragmentActivity`. The
  biometric prompt is a Fragment; on a plain `FlutterActivity` it throws
  the moment the user first taps Unlock.
- **iOS** — `NSFaceIDUsageDescription` is now in `Info.plist`. Without it
  the app is **rejected at review** and crashes on first use.

---

## 7. Queued

| Item | Note |
|---|---|
| **Identity Correction** | §4. Blocked on the admin question |
| Notifications screen | Settings half can be built now; the first-Journey prompt needs push to exist |
| Manage Account | Five exits. **Reset profile** still has open questions — §8 |
| Restore Purchases | On the IAP checklist |
| Reference-code blocking | OA-160 |
| Guardian gender governance review | Ordered 2026-08-06, outstanding, gates the relationship list |
| Roadmap | OA-156 (7 RPCs still on `p_match_id`) → OA-159 → entitlements |

---

## 8. Open — raised, not answered

1. **Chapter 1 ignores frozen fields silently.** `zyra_create_profile`
   returns `name_only` and the client discards it, so someone re-entering
   onboarding and changing their date of birth gets no feedback — the
   change simply does not happen. The fix is that the fields should not be
   editable in the UI once `first_published_at` is set; the column is
   already granted for SELECT so the client can ask. **This is now the
   most visible remaining defect**, because closing the loophole made more
   people reach it.

2. **`surname_line` and `bio` have no length limit** — the same defect
   `first_name` just had, on columns rendered in the same places. Not
   fixed here because there is no agreed limit, and inventing one inside a
   migration would be a decision smuggled in rather than taken.

3. **"Reset profile" — what happens to everything attached?** Guardians,
   unlock credits, an Active Journey with another person who is owed
   something, and the people who Considered them. If the answer is "all of
   it goes", it is delete-and-signup with a friendlier name.

4. **Should the Apple relay explanation appear at sign-up** — while the
   user can still choose otherwise — rather than only in Settings, where
   it explains a decision already made?

5. **Is identity verification in scope before launch?** It changes the
   shape of §3 and unblocks the name-change history deferred above: a
   frozen DOB is worth something behind a document check and nothing
   without one, and a name changed after verification must **lose the
   badge** rather than silently keep it.
