# ZYRA — Guardian Page: Holistic Review

**Status:** FOR REVIEW — nothing built
**Date:** 2026-08-06 · **Origin:** Founder review, 10 points
**Brief:** *"Review this page holistically rather than implementing these
points individually… Guardians are one of ZYRA's defining features."*

---

## The diagnosis, before the fixes

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

## What I would build

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

## What I need from you

1. **Verified** — agree to drop it, and treat real verification as its own
   feature?
2. **Pending invitations** — option **B**, the optional "who is this for?"
   label?
3. **Remove Guardian** — second pass, after the read-only page?
4. **Guardian activity** — I am proposing this and you did not ask for it.
   It is the difference between a prettier list and a page that feels
   important, but it is the largest piece of work here. Worth it?

Six-layer dependency review to follow once these are settled — no
implementation before you have seen the map.
