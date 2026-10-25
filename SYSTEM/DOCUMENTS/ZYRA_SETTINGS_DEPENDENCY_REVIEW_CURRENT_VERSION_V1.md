---
id: DOC-ZYRA-0211
type: REPORT
status: CURRENT
feature: IDENTITY AND SIGN-IN
purpose: ZYRA — Settings: Six-Layer Dependency Review
links: []
owner: ZYRA chat
---

# ZYRA — Settings: Six-Layer Dependency Review

**Status:** FOR REVIEW — two blockers before implementation
**Date:** 2026-08-06 · **Standard:** `SIX_LAYER_REVIEW_STANDARD_CURRENT_VERSION_V1.md`
**Follows:** `ZYRA_SETTINGS_REVIEW_CURRENT_VERSION_V1.md` + Founder structural revisions

---

## Four things in the brief do not exist

Checked against the database and the auth layer, not assumed.

| Brief item | Reality |
|---|---|
| Password / Sign-in & Security | **ZYRA is OAuth-only.** No password exists for anyone |
| Membership: Free / One / **Family** | No Family tier. `plan_type` allows four values, none of them Family |
| Export My Data / Data Export | **Nothing built.** No table, no RPC, no code |
| Notifications (5 categories) | The 3 that exist **are not persisted** |

### 1. There is no password, for anybody

`zyra_auth.dart`, line 3, quoting your own instruction of 2026-07-18:

> *"Google + Apple ONLY: no password, no email login, no phone login, no
> magic link."*

So "Sign-in & Security" contains exactly two truthful things: **which
provider you used**, and **sign out**. There is no password to change and no
email ZYRA owns or can alter.

That is not a gap to fill — it is a deliberate architecture, and a good one.
The section should say so plainly:

```
SIGN-IN & SECURITY
  Signed in with        Google
                        shakeel@gmail.com
  ZYRA never stores a password. Your sign-in is
  managed by Google.
```

**Recommend:** keep the section, rename nothing, and let it be short. A
section that honestly has two rows is better than one padded to look busy.

### 2. "Family" membership does not exist

`subscriptions.plan_type` CHECK: `seeker_basic`, `seeker_premium`,
`wali_basic`, `wali_premium`. In use today: three of those four.

**`seeker_premium` IS ZYRA One** — a mapping that has already caused one
production bug, when `grant_zyra_one_credits` checked for a `plan_type` of
`'zyra_one'` that can never exist.

**Recommend:** show Free / ZYRA One / Guardian+ — the tiers that exist. If
Family is a real forthcoming product, it is a pricing decision with its own
entitlements, not a label to add to a summary card.

### 3. Data Export is a feature, not a settings row — and it is listed twice

No table, no RPC, no code. This is **UK GDPR Article 15**, and OA-155
classified every column's ownership specifically to make it possible — so
the groundwork exists and the feature does not.

It is also in your structure **twice**: Account → Export My Data, and
Privacy → Data Export. One of them should go; Privacy is the better home.

Three of its rules are still **open solicitor questions** and cannot be
answered by engineering — message export, ratings disclosure, and evidence
attachments. Building an exporter before those are settled means deciding
them by accident.

**Recommend: out of scope here.** A row that opens "coming soon" is the
dumping-ground outcome §8 warns against.

### 4. Notification toggles are not saved — and two of the new ones are consent

The three existing toggles write to `AppState.notifyNewMatches` and friends.
**In memory. There is no `notification_preferences` table.** The screen's
own header comment admits it.

Expanding three unpersisted toggles to five makes that worse, and two of the
new ones change its nature:

> **Marketing Emails** and **Product Updates** are consent categories under
> UK GDPR and PECR.

A marketing-consent switch that forgets on restart is not a cosmetic bug. It
means the record of consent does not exist, the user's withdrawal of consent
is not honoured, and neither is evidenced. That is a compliance problem
before it is an engineering one.

**Recommend: persist notification preferences BEFORE adding the categories.**
One table, one RPC, and it must include a timestamp per category so consent
and its withdrawal are both evidenced.

---

## Layer-by-layer, for what remains

**L1 Schema** — one new table, `notification_preferences (user_id, category,
enabled, updated_at)`. Nothing else. Deactivate uses `profiles.is_active`,
which is already writable.

**L2 RLS** — one policy set on the new table, own-row only. No changes
anywhere else: everything Settings reads is already the caller's own data.

**L3 RPCs** — one to set a notification preference. Compatibility editing
reuses `ZyraSeekerDetailsService` and `ZyraOnboardingAnswersService`, which
both exist and both already write.

**L4 Triggers** — none.

**L5 Client** — new `settings_screen.dart`; `profile_screen.dart` loses the
Settings section AND the duplicated Connections rows; the compatibility
editors are new screens; `notification_settings_screen.dart` rebuilt on real
persistence.

**L6 Docs** — schema, ownership classification for the new table, and
`ZYRA_SETTINGS_REVIEW` updated with these findings.

### Dependency review

| Question | Answer |
|---|---|
| Which RPCs? | 1 new; 2 existing services reused unchanged |
| Which client code? | 4 files, 2 new |
| Which policies/grants? | 1 new set; **no existing policy changes** |
| Which docs? | 3 |
| Approved-but-unbuilt architecture? | Data Export (Art. 15) — deliberately deferred; theme/language — omitted until real |
| Anything else? | `profiles.is_active` already drives Browse visibility. "Deactivate Account" and Privacy's "Profile Visibility" would be **two switches on one column** — see below |

### The one collision worth naming

**Deactivate Account** (§5, Advanced) and **Profile Visibility** (§6,
Privacy) would both write `profiles.is_active`. Two controls in two sections
silently setting the same column is how a user turns one off, sees the other
still on, and stops trusting the page.

**Recommend:** Privacy keeps "Visible in Browse" as the everyday control.
Advanced's Deactivate does more than hide — it is a stated intent to step
away — and needs its own column if it is to mean anything different. Until
it does, listing both is offering a choice the data cannot keep.

---

## Two blockers, then I build

1. **Notification persistence** — build the table first, or ship five
   toggles that forget? I would not ship consent categories unpersisted.
2. **Data Export** — confirm out of scope for this work.

Everything else in your structure is buildable as specified.
