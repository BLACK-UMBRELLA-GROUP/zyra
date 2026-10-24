# ZYRA — Guardian Page: Review and Current Implementation

**Status:** CURRENT_VERSION — QUIET SECTIONS APPROVED AND PROMOTED AS THE OFFICIAL SEEKER GUARDIAN PAGE
**Date:** 2026-08-06; implementation amendments 2026-08-26–28 and 2026-09-17 · **Origin:** Founder review, 10 points
**Brief:** *"Review this page holistically rather than implementing these
points individually… Guardians are one of ZYRA's defining features."*

> **CURRENT IMPLEMENTATION AMENDMENT — 2026-08-27:** The original review below
> is retained as decision history, not as a statement that nothing exists.
> Guardian invitation status/actions now live on Dashboard. The Seeker Guardian
> page shows linked Guardians, detail and add flows through five large Focus
> Carousel information comparisons. Every earlier option set, including
> Guardian Brief / Connection Path / Profile Mosaic / Role Chapters / Current
> Focus, is superseded. The current five remain
> experimental and are **not** an approved final design. The bearer-code
> limitation in Gap 3 remains true.

> **CURRENT IMPLEMENTATION AMENDMENT — 2026-08-28 · DR-ZYRA-216 /
> OA-ZYRA-264:** Guardian Pulse is now the production Route-2 composition base
> in the existing near-full-page envelope. Shared Path, Action Board, Activity
> Flow and Living Link remain authorised-developer-only comparisons pending
> Founder selection; they are not five production interpretations. Guardian
> reads now preserve loading, successful empty and unavailable. Link/activity
> failure keeps last-known linked people visible where available and offers
> Retry instead of presenting false empty. The production summary shows role,
> one current state and at most two real activity rows.

> **CURRENT IMPLEMENTATION AMENDMENT — 2026-09-17:** The authorised Developer
> Access Guardian destination now exposes five replacement one-page comparisons
> through **Actions → Page options → Guardian Page Design**: Full profile canvas,
> Snapshot first, Swipe stack, Quiet sections and Journey focus. Every comparison
> uses a horizontal Guardian PageView, Main-first ordering, quiet position dots,
> a real Main Guardian **Share full Journey history** switch, and the current
> obligation where available. There is no relationship timeline and no
> instructional “Swipe to view {name}” caption. Ordinary member accounts retain
> the existing production Guardian manager until the Founder selects a final
> design. This supersedes the earlier five-design comparison lab but does not
> approve any candidate for production.

> **CURRENT IMPLEMENTATION AMENDMENT — 2026-09-17 · FOUNDER SELECTION:** The
> Founder selected **Quiet sections** as the official Guardian page and
> instructed removal of the other options from the toggle. Quiet sections now
> renders for ordinary accounts and authorised Developer Access alike. The
> Guardian Page Design group, comparison enum/state and four rejected
> compositions were removed from live source. Horizontal Guardian swiping,
> quiet dots, Main-first ordering, the Main Guardian Journey-history switch,
> current obligation, no relationship timeline and no swipe caption remain.

---

## Current as-built page

The Seeker Guardian destination now uses one official **Quiet sections** page
for linked Guardians in every account mode. It uses the existing linked-person,
activity and consent callbacks and preserves loading, unavailable and empty
states through the established manager fallback.

Main is ordered first. Horizontal swiping moves directly between Guardians and
quiet dots show position; no button, separate detail route or instructional
caption is used. The page contains the Guardian identity, status, linked date,
Journey access and a current obligation only when truthful activity exists. It
contains no relationship timeline.

The Main Guardian receives the real adaptive **Share full Journey history**
switch. Additional Guardians receive a read-only **Limited Journey summary**
state. In local sample preview the switch changes local state only. With live
data it reads and writes through the existing consent callback, does not update
optimistically, and keeps the last confirmed value if a mutation fails.

The top-right Add Guardian route and empty/unavailable invitation boundary are
retained. The contextual Page options menu retains source and Guardian-count
test controls but no longer contains a Guardian design group. The four rejected
layouts and their comparison state were removed after Founder selection.

### 2026-09-17 promotion evidence

| File | Current responsibility | SHA-256 |
|---|---|---|
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | Guardian source/count scenarios with comparison state removed | `742c58c5e9bfb79e92a3c2a40bf1edd5e9d4e34fb38b16e954006e1670d38cd1` |
| `SOURCE/lib/dev/dev_scenario_panel_v2.dart` | Guardian Page options without design alternatives | `35a34be26cf86df3192a9678e2cf37110e0be7fc5355bbf9fcacb79bda18ce12` |
| `SOURCE/lib/screens/wali/seeker_wali_tab.dart` | Canonical page routing for ordinary and developer accounts | `f154aa50015955caa2d4c4121a30cca9822f6afef72aaace2c80cad7cdee62ed` |
| `SOURCE/lib/screens/wali/seeker_guardian_designs.dart` | Official Quiet sections page | `4fddfd298c80dd78b2883620635b06c63ff6efdc168cc638ad4e53b54c705ce2` |
| `SOURCE/test/guardian_design_control_test.dart` | Promotion and rejected-option removal contract | `86f5885ed26a130ea78249aa33b0399bb4681b75b8fde8c4302dd19f94a873b7` |
| `SOURCE/test/guardian_one_page_designs_test.dart` | Official page render, swipe/dots and preview consent | `88f3a4204ba63a9ac97a182f69c01d29bc495925aa1d51613ab5b8f591d97187` |
| `SOURCE/test/guardianship_manager_phase1_test.dart` | Empty/manager compatibility | `8decbce5eac82ee27618538c6f6e5fd5ce042dd70bd9cf4272eb8fe80872d4f5` |
| `SOURCE/test/seeker_wali_tab_truth_test.dart` | Live activity and consent truth boundaries | `7c5d855b854aae37646cecd1d85a089acca75cda03218a3605c330c806cc4235` |

Measured after promotion: the related Guardian/control suite passed **17/17**
and full `flutter analyze` passed with no issues. The structural checker added
no new findings; its existing `main.dart` internal-preview member finding
remains analyzer-clean and outside this change. No migration or SQL was
created or applied. TestFlight was not changed.

Invitation workflow is no longer duplicated here:

- Dashboard shows live sent/pending invitation state and cancellation.
- Guardian `+` opens the existing bearer-code review/accept flow alongside
  invite-code generation; Dashboard no longer presents a generic code-entry row.
- Named received invitation rows exist only as developer preview and are
  labelled `Preview`, because `wali_invites` still has no recipient field.
- The Guardian page retains the add/link entry point; it does not retain the
  old pending/received list.

### Current files and evidence

The following 2026-08-28 rows supersede older hashes for the named files:

| File | Current responsibility | SHA-256 |
|---|---|---|
| `SOURCE/lib/services/zyra_wali_link_service.dart` | Typed invite/link/activity results plus safe four-type parsing | `3ff3486b51d4633716b42339cff4147d4416faa2e39876a738af7bf184b4553a` |
| `SOURCE/lib/screens/wali/seeker_wali_tab.dart` | Loading/available-empty/unavailable host with Retry | `0f48b4ea79109c2f2109f9dfa9fe77759a634b8e8ec302d4c3aa0dd56e36e9be` |
| `SOURCE/lib/screens/wali/seeker_guardian_designs.dart` | Production Guardian Pulse base and four dev-only sibling compositions | `c25172cf10e9747b515e7fca3356f3b0f18d54cb5cefe79179774835212a1a4d` |
| `SOURCE/lib/widgets/zyra_guardian_invitation_dashboard.dart` | Typed pending-invite unavailable/empty/last-known boundary | `e32a7b2454ece6e4bef64ac9f341b4a5ba8f5fb6c87e6b7500fe88232b142989` |
| `SOURCE/test/zyra_wali_link_service_test.dart` | Four activity types, malformed/unknown safety and source result states | `2d297ce62546f78b7907f93a95c1ed60711b88b83c65895fdbdb825bc7aefc2f` |
| `SOURCE/test/seeker_wali_tab_truth_test.dart` | Failed versus empty and independent retry coverage | `c5dbd176e87790f7b9c4b0eff9edcf7cdc1076fc1bd84cfac1f6d7c73d27b422` |
| `SOURCE/test/guardian_page_design_test.dart` | 0/1/6 links, privacy, Pulse density, 130% text and nav clearance | `3a87b8e6872c78ac0493db698fc3ad8b93d0a419d154490eef7b3488789ae87a` |
| `SOURCE/test/guardian_invitation_dashboard_test.dart` | Successful empty, unavailable Retry and last-known invite preservation | `d90af4d4411c21c2c9bd132f2d5fbae7479ed6fe05d013d5b0d1d9adce0acbdc` |

Measured 2026-08-28: the combined OA-ZYRA-264 focused suite passed **119/119**;
the governed full gate passed all checks and 215 render variants. The final
report is
`SYSTEM/RESOURCES/UI_GATE/REPORTS/ZYRA_VISUAL_AUDIT_2026-08-28_27fcffb9.md`.
No migration or SQL was created/applied.

The privacy wording matrix now enforced in code/tests is:

| State/type | Allowed summary wording |
|---|---|
| linked | `Guardian link active` / `Linked {date}` |
| suggested | `Shared a profile suggestion` |
| review_answered | `Family Review completed` |
| review_waiting | `Family Review is open` / `Opened {date}` |
| successful empty | `No recorded activity yet` |
| unavailable | `Activity could not be refreshed` + Retry |

Raw review decisions, a suggestion's third-party name, “accepted invitation”
and “connected and ready” remain prohibited on this summary surface. Unknown
types are rendered safely; malformed identity/type/timestamp rows are rejected.

| File | Responsibility | SHA-256 |
|---|---|---|
| `SOURCE/lib/screens/wali/seeker_wali_tab.dart` | Data host and shared callbacks | `5bdcd86517ce695fd93a5509f026fd87f5d6eb08438f82534e0cc1ebb87d0134` |
| `SOURCE/lib/screens/wali/seeker_guardian_designs.dart` | Shared carousel controller, top-right add control, unchanged SafeArea/nav-aware envelope and Guardian pulse / Shared path / Action board / Activity flow / Living link | recorded in the final 2026-08-27 evidence table |
| `SOURCE/lib/screens/wali/link_guardian_panel.dart` | Guardian `+` destination with enter-code and create-code paths | `8ed079b4efcfff6b8604a99e481b5e442ac3d4f572ee153113eb15d479f34bf6` |
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | Current five-design enum/state/reset and mock Guardian fixtures; reset = Guardian pulse | recorded in the final 2026-08-27 evidence table |
| `SOURCE/lib/dev/dev_scenario_panel_v2.dart` | Page-aware Guardian Page Design selector and current comparison explanation | recorded in the final 2026-08-27 evidence table |
| `SOURCE/lib/screens/wali/guardian_detail_screen.dart` | Established management route; stale header comment reconciled with the guarded Remove Guardian implementation | `3efca6ba3ffd279df714b2a30f99de0e011e0baecd9ff22674cc8e728f705cef` |
| `SOURCE/test/guardian_page_design_test.dart` | Empty/one/six, top-right add placement/action, callback parity, swipe selection, Main ordering/reorder, structured-content assertions, Dynamic Island/nav clearance, real detail, three surfaces, compact and 130% text | recorded in the final 2026-08-27 evidence table |
| `SOURCE/test/guardian_invitation_dashboard_test.dart` | Dashboard collapse/status coverage and Guardian `+` code-entry route | `81cd6659b2c307d3f07ca559bfc65a559e910f780b6f7d16323d7bfe035a8c9e` |
| `SOURCE/test/guardian_design_control_test.dart` | Exact five-option order, page-aware selector and Guardian pulse reset | recorded in the final 2026-08-27 evidence table |

Measured 2026-08-27 for the current five: focused Guardian/control suite
**16/16**. It covers empty/one/six Guardians, the same add/open callbacks, all
three global surfaces, 320 px width at 130% text, long/missing fields and the
real floating-navigation clearance. The broader final Flutter/visual/build and
wireless-device results are recorded only after the combined release check.
Founder visual selection remains pending. No migration was created or applied.

### Final current-five evidence — 2026-08-27

| File | SHA-256 |
|---|---|
| `SOURCE/lib/screens/wali/seeker_guardian_designs.dart` | `b3b0dc177b735206b4b0ad70fee005a87aa5702a3fd9a0cc01bd9dac0066b429` |
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | `96e43e6f402614592d20ede610dfef3a9a02112b48e9ce392f049b95b26de741` |
| `SOURCE/lib/dev/dev_scenario_panel_v2.dart` | `f03e045d81d09c0f74d0e19921e29d8f6207aa169eda1250885bfe37bb1cca71` |
| `SOURCE/test/guardian_page_design_test.dart` | `e35363800d4afc7e465621a2a170204df63d0797223f02654015293eed27b2e1` |
| `SOURCE/test/guardian_design_control_test.dart` | `b9c98e3b9cbcb4db4fc22024d7d5740d612f6f38f63d991507273a681a73c418` |

Focused Guardian/control measurement: **16/16**. Full Flutter regression:
**498/498**. Direct visual/no-overflow matrix: **212/212**. Analyzer and
structural checker: clean. Signed iOS profile build: **34.8 MB**; the paired
iPhone received the build through `flutter install --profile` over the wireless
debugging connection. Apple's separate CoreDevice launch probe timed out, so
this handover does not claim automated launch/process observation. No migration
or database change was involved.

## Historical diagnosis, before the fixes

The page reads as a contacts list because **it shows who your Guardians
are and never once shows them doing anything.**

Every item on it is an attribute — name, relationship, Main. Attributes are
what a contacts app stores. What makes a person feel present is *evidence of
them acting*: Ibrahim reviewed your Journey with Yusuf on Tuesday. Abdul is
waiting on you. Hassan has not opened the app since March.

So the strongest single change is not a badge. It is **giving each Guardian
a last-activity line**, and giving the page a state — *who is waiting on
whom right now*.

Badges make a card look important. Activity makes a person *be* important.
Most of the ten points below get better when read through that lens, and
three of them stop being necessary.

---

## The honest inventory

Checked against the database, not assumed.

| Your point | Data exists? | Notes |
|---|---|---|
| 1 Tappable → detail page | **partly** | See the three gaps below |
| 2 More identity per card | **partly** | Relationship ✓, Main ✓, Verified ✗ |
| 3 Circular + button | ✓ | Pure UI |
| 4 Intro paragraph | ✓ | Copy only |
| 5 Visual hierarchy | ✓ | Main/Additional split already exists |
| 6 Status chips | **partly** | Main ✓ Active ✓ Pending ✓ **Verified ✗** |
| 7 Pending Invitations | **partly** | See gap 3 — no name to show |
| 8 Remove city | ✓ | **Already true** — this page never showed city |
| 9 Summary counts | ✓ | All derivable, no schema |
| 10 Empty state + button | ✓ | Exists; needs restyling, not building |

---

## The three gaps — and one I would not close

### Gap 1 — "Verified" does not exist, and I would not invent it

**Recommend: drop it from this work entirely.**

There is no verification concept anywhere in ZYRA. Zero columns matching
*verif*, *trust*, or *kyc*. Nothing is checked about a Guardian beyond the
fact that somebody sent them a code and they typed it in.

A "Verified" chip would therefore be decoration that reads as an assurance.
On a marriage platform that is not a cosmetic problem:

- A Seeker's family will read "Verified" as *ZYRA checked this man is who he
  says he is*. Nothing checked anything.
- The people relying on it hardest are exactly the people the product exists
  to protect.
- It is the one claim on the page that could be quoted back at us.

**What is honestly available today**, and reads nearly as strongly:

| Chip | Means | True? |
|---|---|---|
| **Main Guardian** | acts on the Journey | ✓ `is_main` |
| **Linked 3 Mar** | accepted the invite | ✓ `created_at` |
| **Active** | link is live | ✓ `status` |
| **Invitation Pending** | sent, not accepted | ✓ `wali_invites` |

"Linked 3 March" does the job you want a badge to do — it makes the
relationship feel real and established — and every word of it is true.

If you do want real verification, it is its own feature with its own
decisions (what is checked, by whom, what happens on failure, what a family
is entitled to rely on). Worth doing. Not worth faking first.

### Gap 2 — Guardians have no photos

**5 Guardian profiles, 0 photos.** Guardian onboarding asks name, date of
birth and relationship. There is no photo step, so a detail page with a
photo shows a placeholder for every Guardian who exists.

Two honest routes:

1. **Add a photo step to Guardian onboarding** — but you have ringfenced
   Guardian onboarding pending the gender governance review, so this waits.
2. **Design for the initial, deliberately.** A large gradient monogram, well
   made, looks intentional. A grey silhouette looks broken.

**Recommend 2 now, 1 later.** It also keeps a real decision open: whether a
Guardian's face should be visible to a Seeker who unlocks his daughter's
profile is a privacy question nobody has answered.

### Gap 3 — A pending invitation has no name

This is the one that changes your design.

`wali_invites` holds: `token, inviter_id, inviter_role, status, created_at,
accepted_at, accepted_by, expires_at`.

**There is no recipient.** The flow is "generate an 8-character code, share
it however you like" — no email, no phone, no name. So:

```
Pending Invitations
  Ahmed
  Waiting for acceptance
```

cannot be built. There is no Ahmed. The system does not know who the code
was for, and will not until they type it in.

Three options:

| | What it shows | Cost |
|---|---|---|
| **A** | `Invite code 7QK4XP2M · sent 2 days ago · expires in 5` | none — build today |
| **B** | Ask "who is this for?" when generating; store a label | one nullable column |
| **C** | Real invitations by email/SMS | a delivery backend; not v1 |

**Recommend B.** One optional free-text field, shown only to the person who
sent it, never to the recipient. It costs almost nothing and it is what
makes the section read the way you described — *"the Guardian network feels
alive"* — because a list of codes does not feel alive, and a list of names
does.

Worth noting B is the only place I would put free text in this feature, and
it is safe precisely because it is a private note-to-self, not an identity
claim.

---

## Superseded 2026-08-06 proposal (not the current UI)

### The page

```
GUARDIANS

Guardians support your marriage journey and speak
for your family when decisions are needed.

  1 Main · 2 Additional · 1 Pending        <- state, one line

MAIN GUARDIAN
┌────────────────────────────────────────┐
│  (A)  Abdul                            │
│       Father · Main Guardian           │
│       Linked 3 March · reviewed your   │
│       Journey with Yusuf on Tuesday    │  <- presence
└────────────────────────────────────────┘

ADDITIONAL GUARDIANS
  (H)  Hassan · Paternal Uncle · Linked 12 May
  (I)  Ibrahim · Brother · Linked 2 June

PENDING INVITATIONS
  ( )  Ahmed — waiting · expires in 5 days

                  ( + )
```

Every card taps through to a detail page.

### The detail page

Available now: monogram, name, relationship, Main status, linked date, link
status, and — the part that earns the page — **their activity on your
Journeys**.

Not yet: photo (gap 2), permissions (the Wali One capability model is
documented but unbuilt), verification (gap 1).

**Remove Guardian** belongs here and needs care: `wali_links.status` already
supports `'removed'`, but removing your *Main* Guardian mid-Journey has
consequences nothing currently handles — `auto_designate_main_wali` promotes
on the first *active* link, and a Family Review awaiting that person's
decision would be orphaned. **Recommend it ships in a second pass**, after
the read-only page, rather than being rushed in beside a visual refresh.

### Why the summary line matters more than it looks

`1 Main · 2 Additional · 1 Pending` is the smallest change with the largest
effect on your actual complaint. A contacts list has no state. A management
surface tells you the state of the thing you manage in one line, before you
read anything else. It also needs no schema.

---

## Superseded 2026-08-06 questions

1. **Verified** — agree to drop it, and treat real verification as its own
   feature?
2. **Pending invitations** — option **B**, the optional "who is this for?"
   label?
3. **Remove Guardian** — second pass, after the read-only page?
4. **Guardian activity** — I am proposing this and you did not ask for it.
   It is the difference between a prettier list and a page that feels
   important, but it is the largest piece of work here. Worth it?

These questions are retained as history. The live five-way experiment and
Dashboard invitation move above supersede the old “nothing built” position.
