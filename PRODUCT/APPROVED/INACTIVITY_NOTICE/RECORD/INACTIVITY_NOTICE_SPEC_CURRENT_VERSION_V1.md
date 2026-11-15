---
id: DOC-ZYRA-0488
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 32 - the 2-year inactivity notice - five emails before and after an account reaches 2 years unused, removal of its Ended Journeys 14 days after, and the one-time "Welcome back" item in My ZYRA
links: [OA-ZYRA-317, AD-AIOS-115]
owner: ZYRA chat
---

# 2-YEAR INACTIVITY NOTICE — SPEC — V1 (LOCKED 12 NOV 2026)

Reference: prototype V206 (private copy `BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V226.html`) —
side list **2-year notice → Email** (strip above the phone switches emails 1–5) and **Welcome back · My ZYRA**. No master
pictures (charter rule 13).

## 1. Rules (Founder 12 Nov)
| Rule | Detail |
|---|---|
| Who | Only accounts that **have Ended Journeys** and have not used ZYRA for 2 years. No Ended Journeys → no emails, nothing removed |
| Removal | **14 days after** the account reaches 2 years unused, its Ended Journeys are removed exactly as **Remove from my Journeys** does (the other person keeps their copy). Replaces the 16:35 "30 days later" |
| Cancelling | Using ZYRA at any point before removal cancels the notice; the count starts again |
| Nothing else changes | Profile, Guardians, membership and active Journeys are untouched |

## 2. The five emails
Greeting **"Assalaamu alaikum <first name>,"**. Never name or show another member — only the number of Ended Journeys.
Each email: ZYRA wordmark, a status chip, the body, gold **Open ZYRA** button (opens the app), then muted lines, signed
**The ZYRA team**. Dates below are for an account reaching 2 years on 12 Nov (removal 26 Nov).

| # | Sent | Subject | Chip (colour) | Body |
|---|---|---|---|---|
| 1 | 14 days before 2 years | **We’ve missed you at ZYRA** | Removal on <date> (muted) | You haven’t opened ZYRA for almost 2 years. · To protect your privacy, we’ll remove your **<n> Ended Journeys**, with their Timelines and messages, on **<date>**. · Want to keep them? Just open ZYRA before then. |
| 2 | 7 days before | **Your Ended Journeys: removal on <date>** | 3 weeks left (muted) | as 1 |
| 3 | On the 2-year day | **Your Ended Journeys will be removed on <date>** | 14 days left (gold) | You haven’t opened ZYRA for 2 years. · then as 1 |
| 4 | 7 days after | **7 days left to keep your Ended Journeys** | 7 days left · last reminder (red) | This is your last reminder. You haven’t opened ZYRA for 2 years. · then as 1 |
| 5 | 14 days after (removal day) | **Your Ended Journeys have been removed** | Removed today (muted) | As ZYRA wasn’t opened for 2 years, we removed your **<n> Ended Journeys** today, with their Timelines and messages. This can’t be undone. · Your profile, Guardians and membership are still here whenever you’re ready. |
Muted lines: emails 1–4 **Your profile, Guardians and membership stay as they are.**; all five **No longer using ZYRA? You can
delete your account in Settings → Advanced → Delete account.** "1 Ended Journey" when n = 1.

## 3. My ZYRA — "Welcome back" (once)
When a member opens ZYRA while a notice is open (after email 1, before removal): Needs-you item, newest first, icon history —
**Welcome back, <first name>** / **You were away for a while. Your Ended Journeys are kept — nothing was removed.** / gold
**View Ended Journeys** → Ended Journeys. Shown **once**; gone after it is tapped or the member leaves My ZYRA. Returning after
removal: no item.

## 4. Not in this LOCK
Push notifications for the notice (none). Sending email needs an email service (Fable, server). The wording above is final.

## Change log
| Date | Version | Change |
|---|---|---|
| 2026-11-12 | V1 | LOCKed by the Founder (`LOCK_RECORD.md`, LOCK 32) |
