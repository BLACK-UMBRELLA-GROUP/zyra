FEATURE NAME
USER FEATURES
Group: 1 — Business Rules

============================================================
SUMMARY
============================================================

Purpose:
Defines subscription tiers, feature entitlements, and
business rules for Seekers and Guardians.

Owns:
- Seeker Plans
- Guardian Plans
- Subscription Features
- Access Permissions

Superseded 2026-07-12: both tables below rebuilt from
ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V5 (Part 1, Sections 6-7) and
WALI_ARCHITECTURE_CURRENT_VERSION_V6 (Guardian Permissions Model).
The old 5-column Seeker table (Basic/Pro/Premium × Guardian linked
or not) and 3-tier Guardian table (Basic/Pro/Premium, including a
Guardian "Approve match / Concerned / No Opinion" vote) describe a
model that no longer exists — there is no Guardian approval step in
the current product; the Guardian's involvement is the Family
Review Period (continue/pause), a different mechanism. Where
the old table listed a feature not confirmed in either current
source document, it has been dropped rather than guessed at —
see note at the bottom.

------------------------------------------------------------
SEEKER PLANS
------------------------------------------------------------

| Feature                                  | ZYRA Basic        | ZYRA One   |
|-------------------------------------------|:------------------:|:----------:|
| Create profile, upload photos             | ✅                 | ✅         |
| Browse                                    | 50 every 4 hours   | Unlimited  |
| Save                                      | 10/day             | Unlimited  |
| Like                                      | 10/day             | Unlimited  |
| Journey Queue (passive)              | Unlimited          | Unlimited  |
| Active Journey slots                      | 1                  | 1 (unchanged — Pause/Resume instead of more slots) |
| Pause / Resume Journey                    | ❌                 | ✅         |
| Incoming Potentials shown immediately     | ❌                 | ✅         |
| Mutual Save Detection                     | ❌                 | ✅         |
| Priority Discovery                        | ❌                 | ✅         |
| Messaging, read receipts (Active Journey) | ✅                 | ✅         |
| Profile Unlock on Active Journey creation | Standard           | Plus       |
| ZYRA Intelligence (recommendations, insights, summaries, Guardian AI Summary) | ❌ | ✅ |
| Timeline                                  | ✅                 | ✅         |
| Link a Guardian                               | ✅                 | ✅         |
| Includes one bundled Guardian+ entitlement | ❌            | ✅ (one linked Guardian) |

------------------------------------------------------------
GUARDIAN PLANS
------------------------------------------------------------

| Feature                                | Standard Guardian | Guardian+ |
|------------------------------------------|:-------------:|:--------------:|
| View Journey progress                   | ✅            | ✅             |
| View messages                           | ✅            | ✅             |
| View Timeline                           | ✅            | ✅             |
| Receive Family Review Period notifications | ✅         | ✅             |
| Continue / Pause at Family Review Period | ✅            | ✅             |
| Raise concern / flag                    | ✅            | ✅             |
| Receive safety alerts                   | ✅            | ✅             |
| Guardian Network access                     | ❌            | ✅             |
| Family Introductions                    | ❌            | ✅             |
| Suggest profiles                        | ❌            | ✅             |
| Guardian AI Summary                         | ❌            | ✅             |

Received either as the one entitlement bundled with a Seeker's
ZYRA One, or purchased independently by the Guardian (£9.99/month)
— identical capabilities either way (AD-081).

Note: the old table's "Approve match / Mark as Concerned / No
Opinion", "Read chats" as a Guardian-only unlock, and "Guardian Premium
↔ Guardian Premium chat" rows are not present in either current
source document and have not been carried forward. If any of
these are still real product behaviour, they need re-confirming
against Guardian Architecture V6 directly rather than assumed from
this table.

============================================================
APPROVED TO-DO LIST
============================================================
(None listed in source — add as decisions are made.)
