# CONTRADICTION REVIEW — Guardian Network Draft 2 (D14 model)

**Reviewer:** Fable · 2026-08-23 · $0.00 API
**Candidate:** `02_DRAFT_v8_d14.dart` (2,129 lines) — replaces live `wali_network_screen.dart` (base sha256 `2c85edc0810f578f…`)
**Contract:** `ZYRA_GN_BUILD_CONTRACT_CURRENT_VERSION_V1.md` (44 rules; passes the engine's AC-18 sequence gate)
**Scope honesty:** this is a MOCK preview draft (Rule 44) — server-side rules verify as NOT EXERCISED by design; UI-expressible rules verified in code. Review performed pre-apply per AC-6/AC-11; flutter analyze is the remaining gate and runs at apply.

| Rules | Verdict | Evidence in candidate |
|---|---|---|
| 1–3 (context, single-Seeker, selector) | HELD | No ward → notice; multi-ward unselected → "Choose a Seeker"; one ward → avatar renders static (no tap target); all mock state keyed per ward |
| 4 (composite key) | HELD (mock) | `_stage` keyed `'${ward.id}/${family.id}'`; switching ward switches everything |
| 5–11 (server gates) | NOT EXERCISED | No backend; page states "the algorithm serves eligible families"; no widen/search controls exist |
| 12 (card fields) | HELD | initial · age ("H., 27") · region · band chip (text, never numeric) · relationship label · verified badge · photo per level; no city/full name/occupation anywhere |
| 13–14 (no free text; taxonomy chips) | HELD | Zero input fields; reasons are fixed mock strings |
| 15–16 (ladder; uniformity) | HELD | Rung-0 sheet shows less than Rung-2 sheet; one card widget for all families |
| 17 (action set) | HELD | View · Set aside · Request connection on card; Connect with this family / Not for us / Withdraw / Proceed in Connections; no FIR anywhere; no messaging |
| 18 (silent views) | HELD | Views only open local sheets; analytics rows are actor-side only |
| 19 (Set aside) | HELD | Reversible list, restore button, "30 days while eligible" copy, snackbar confirmation |
| 20 (Suggest unchanged) | NOT EXERCISED | Suggest lives on the Seeker Introductions pipe, outside this screen — correctly absent here |
| 21/27 (single closed state) | HELD | Every closure renders exactly "No longer active"; history rows carry initial · region · state only |
| 22–23 (ladder; serving) | HELD | One served family at a time; advancement only on action with "ZYRA is choosing…" transition; no paging/arrows |
| 24 (merge rule) | HELD | Incoming-pending family renders the merge card ("This family has already requested connection." → Review request), never a normal card |
| 25–26 (silence discipline) | HELD in copy; NOT EXERCISED in timers | 14-day copy on Sent rows; "Not for us" clears internally; cooldown timers are server-side |
| 28–29 (unlock/never lists) | HELD | Rung-2 sheet describes the unlock and names the never-list; **no responsiveness indicators anywhere** (checked: zero "responds within" strings) |
| 30 (access ends) | HELD | Closed rows show the minimal record; no reopen path from history |
| 31–32 (dual proceed; reveal; dashboard boundary) | HELD | Proceed → "awaiting their Wali"; pre-seeded confirmed case completes to the simultaneous-reveal card; footer sends Seeker-stage to the Dashboard |
| 33–34 (consent; photo levels) | HELD (mock) | Three photo levels in the mock model; card-level shows placeholder photo at Rung 0; after-connect shows seal + honest caption, photo at Rung 2; never → seal always |
| 35 (recheck) | NOT EXERCISED | Server-side |
| 36 (calm delivery) | NOT EXERCISED | No push machinery in the draft; no notification code added |
| 37 (authority) | HELD | Role toggle: Additional sees "Ask Main Wali" instead of Request, and Connections renders only "Handled by the Main Wali" — no reciprocal cards |
| 38 (entitlement) | HELD (existing) | Production path keeps the Guardian+ gate untouched |
| 39 (no search) | HELD | No search field, no list of upcoming families, no enumeration surface |
| 40 (live cap) | HELD | `_liveCount` counts sent+connected+proceed; cap card at 3; incoming accept blocked at cap with Rule-40 copy |
| 41 (analytics) | HELD (provisional) | 13 event types emitted through the in-file tracker; dev panel exposes the event log |
| 42 (naming) | HELD | All eight ratified strings appear verbatim |
| 43 (supersession) | HELD | No FIR concept in the file |
| 44 (build discipline) | HELD | All mocks in-file + PROVISIONAL; dev panel kDebugMode-gated; production path = gate + empty states; this review + analyze gate before ready |

**Verdict: READY for apply, subject to the flutter analyze gate.** No invented product rules found; no rule violated in UI-expressible scope. The apply job carries the base-sha guard (AC-10) and restores automatically on analyze failure.
