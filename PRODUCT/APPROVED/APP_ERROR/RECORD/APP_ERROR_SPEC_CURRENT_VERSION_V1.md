---
id: TBC (Fable assigns)
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 23 - one app-error page (cannot connect / server down / session ended) with help, replacing the two error pages that showed one after the other
links: [AD-AIOS-115]
owner: ZYRA chat
---

# APP ERROR PAGE — SPEC — V1 (LOCKED 10 NOV 2026)

Masters (430 × 932 @3x, Ivory, prototype V142) in `../MASTERS/`: e01 offline · e02 server · e03 session · e04 trying · e05 Guardian (same page).

## 1. The problem (Founder, 10 Nov, phone)
When ZYRA could not reach its server, the phone showed **two** error pages: first a bottom card "Couldn't open this page."
(ZY-BYUR, from the Founder-preview launch screen `lib/dev/zyra_founder_launch_screen.dart`, `ZyraCompactRecoverySurface`),
then ~2 s later the full page "We couldn't connect to ZYRA." (ZY-4Z99, `lib/models/zyra_error_state.dart`, offline).
Founder: "there should only be one error message … ensure the error page has solutions".

## 2. Rule
**One error page.** Every app-stopping error (start-up, Founder-preview launch, route that cannot open) shows this one page,
once. No card first, no switch to a second page. Seeker and Guardian apps alike.

## 3. Layout (top to bottom)
| Part | Rule |
|---|---|
| Wordmark | "ZYRA", gold, wide letter spacing, top centre |
| Mark | The existing dot–line–chevron–line–dot mark, gold, centred |
| Title / line | 26 light title, muted 14 line under it — words per kind (§4) |
| Help | Gold small caps **WHAT YOU CAN TRY**, then one floating card with the kind's rows (gold icon, title, muted line) |
| Status | Muted 12, centred, above the button: **Trying again in <n> s** counting down from 15; while trying **Trying again…** (retry kinds only) |
| Primary | Outline pill, gold label: **Try again** (while trying: **Connecting…**, disabled). Session kind: **Sign in again** |
| Secondary | Text button **Contact support** → the existing Help & support page, with the reference shown |
| Reference | Muted small caps **REFERENCE: <code>** (existing reference code) |
| Fill | The help card sits in the middle; spacers share the free height (no dead space at the bottom) |

## 4. Words per kind
| Kind (existing `ZyraErrorKind`) | Title | Line | Card rows |
|---|---|---|---|
| `offline` (the phone has no connection) | You're offline. | ZYRA needs an internet connection to open. | wifi **Check Wi-Fi or mobile data** — "Turn it off and on again, or move closer to your router." · refresh **We keep trying** — "ZYRA tries again on its own while this page is open." · help **Still stuck?** — "Contact support and quote the reference below." |
| `serviceUnavailable` (ZYRA's side not reachable) | ZYRA is taking a moment. | This is on our side, not yours. Your account is safe. | refresh **We keep trying** · lock **Nothing changes while we're away** — "Your profile, Journeys and messages stay as they were." · help **Still stuck?** |
| `sessionExpired` and `previewAccess` | Please sign in again. | For your security, your session has ended. | lock **Why this happens** — "Sessions end after a long time away or a password change." · help **Can't sign in?** — "Contact support and quote the reference below." Primary **Sign in again** (signs out and opens sign-in); no auto-retry |
| `page` (one screen could not open) | We couldn't open this page. | Something didn't load correctly. | refresh **We keep trying** · help **Still stuck?** (Try again reloads that screen) |

Choosing offline vs server: use the app's existing classification (`zyraErrorKindFor`); show **offline** only when the
failure is the phone having no connection; any other failure to reach ZYRA is **server**. No new package or permission.

## 5. Behaviour
| Item | Rule |
|---|---|
| Auto-retry | Every 15 s while the page is open (retry kinds). Success → the app continues to where it was going. Failure → countdown restarts |
| Try again | Retries now; same result handling |
| One page | The Founder-preview launch failure goes straight to this page (remove the compact card). A later error replaces the words on the same page, never stacks a second page |
| Removed | Secondary labels "Return to welcome", "Return home", "Sign out" on error pages (replaced by Contact support / Sign in again) |
| Preview demo | The prototype's "Demo: connection comes back" button is prototype-only. Not in the app |

## 6. Must not change
Inline field errors, banners and empty states; the loading screen before an error; server, database, auth logic.

## 7. Not decided
Keeping the server awake (the free Supabase project pauses after about a week unused — that is what caused the 10 Nov error). For Fable.

## Version history
| Date | Version | Change |
|---|---|---|
| 2026-11-10 | V1 | Founder: "After A · One page + help (Recommended)" (option text "LOCK it") |
