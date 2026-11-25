---
id: DOC-ZYRA-HELPPAGE-V1
type: SPEC
status: CURRENT
feature: HELP AND SUPPORT PAGE
purpose: Spec for LOCK 43 - Settings → Help & support (search, topics, answers in place, Contact us); replaces the old dark help_support page
owner: ZYRA chat
---

# HELP AND SUPPORT PAGE — SPEC — V1 (LOCKED 23 NOV 2026)

## Purpose
This page is where members find answers before they need to write to the ZYRA team. The 23 Nov walkthrough found it still in the old dark style; this replaces it. Founder 23 Nov (Claude chat, clickable): "Lock and queue (Recommended)". The answers rule from HELP_FAQ V1 still applies: any explanation removed from a screen lives here. Fixed prototype reference: `BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ARCHIVE/ZYRA_PROTOTYPE_2026-11-23_V316.html`.

## 1. Where it opens
- Settings → SUPPORT → Help & support.
- Profile → Safety & advice → the Help card's **Help & support** row (Seeker and Guardian, UNITY_PASS V7 §3d/§3e; corrected 24 Nov: the row reads "Help & support", as in the prototype, not "Open Help & support").
- Any other "Help & support" link.

## 2. Layout (hp01–hp05)
1. The title "Help & support" — no on-screen Back (Founder 30 Oct: "not one in app just prototype"): going back is the iOS edge swipe; the prototype's ‹ Back pill sits outside the phone (correction 24 Nov, QUESTIONS 200).
2. **Search** pill: "What do you need help with?" Typing filters the questions as you type, matching words in both questions and answers (hp03). With no matches: "No answers for "<words>". Try other words, or contact us below." (hp04).
3. **Topic pills**, scrolling sideways: All · Getting started · Profiles and Journeys · Guardians · Membership · Safety · Your account. The chosen pill is ivory with a gold border.
4. **Questions grouped by topic** in ivory cards. Tapping a question opens its answer underneath, in 13.5 pt `#4F443A`, with a down chevron; tapping again closes it. Only one answer is open at a time (hp02).
5. **Still need help?** card at the end: "We reply by email within 2 working days." with **Contact us**, which opens Contact support (LOCK 37) (hp05).

## 3. Content
The questions and answers below are the first set, written from the locked rules. **Remove the old-app questions still in `help_content.dart`**, for example "What is the difference between Consider, Save and Pass?". Keep each existing answer only if it matches today's app; otherwise rewrite it in this tone, and list every change in the as-built record. HELP_FAQ V1 entry 1 (Past Journey summaries) is included.

| Topic | Question | Answer |
|---|---|---|
| Getting started | How does ZYRA work? | You build a profile, browse other verified Seekers and send a Journey request. If it is accepted, you walk a Journey of 8 stages together, with your Guardians beside you, until you decide together. |
| Getting started | How do I sign in? | With Sign in with Apple or Google, the same one you used to join. ZYRA has no password of its own. |
| Getting started | Who needs a Guardian? | Every Seeker chooses a Main Guardian, usually a parent or family member, who is part of every Journey. You can add more Guardians and choose what each one sees. |
| Profiles and Journeys | How many Journeys can I hold? | Seeker Basic has 1 Journey place. Seeker One has 3. A request you accept uses a place until the Journey ends. |
| Profiles and Journeys | What happens when a Journey ends? | The Journey moves to Ended Journeys with its Timeline, read only. The other person sees “Journey ended”, never a reason. |
| Profiles and Journeys | Who can see my photos? | Verified members who can see your profile, and their Guardians, through the app. Someone who hasn’t verified sees them blurred. |
| Guardians | What can my Guardian see? | The Journeys you allow, at the stages that allow it. Never your private answers or your Compatibility Unlock details. |
| Guardians | What are Past Journey summaries? | When you switch this on for a Guardian, they can see your Journeys that have ended: the other person’s first name and the dates, nothing else. It is off until you turn it on, for each Guardian separately. Turn it on or off any time on that Guardian’s card in the Guardian tab. |
| Membership | What does ZYRA cost? | Seeker Basic is a one-off £4.99. Seeker One is £29.99 a month after a 14-day free trial. Guardian One is £19.99 a month after a 14-day free trial. Prices are in Membership. |
| Membership | How do I cancel? | In Profile → Membership → Cancel membership, which opens your App Store subscriptions. You keep your plan until the end of the period you paid for. |
| Safety | How do I report someone? | Open their profile, tap ••• and choose Report. A person on the ZYRA team looks at every report within 24 hours. They are never told who reported them. |
| Safety | What is the difference between blocking and reporting? | Blocking stops them seeing or contacting you, straight away. Reporting asks the ZYRA team to look into what they did. You can do both. |
| Your account | How do I take a break? | Pause My Profile in Settings → Privacy hides you from Profiles. Your Journeys and Guardians stay as they are. |
| Your account | How do I delete my account? | Settings → Advanced → Delete my account. Your profile disappears straight away, and you have 30 days to change your mind by signing in again. |

## 4. Masters
`HELP_SUPPORT_PAGE/MASTERS/hp01–hp05` at 430 × 932 @3x.

## 5. Version history
| Version | Date | Change |
|---|---|---|
| V1 | 2026-11-23 | First version (LOCK 43) |
| V1 corrections | 2026-11-24 | No new decision: §2.1 no on-screen Back (QUESTIONS 200); §3 Guardian One trial 14 days, was 7 (QUESTIONS 205); §1 the Safety & advice row name, as UNITY_PASS V7 §3d/§3e and the prototype (question-check pre-flight) |

## Correction 25 Nov (Founder, Claude chat, clickable "Add the extra sentence (Recommended)")
§3 Past Journey summaries answer gains its last sentence from HELP_FAQ V1 entry 1: "Turn it on or off any time on that Guardian’s card in the Guardian tab." No master shows this answer open, so no re-render. Prototype V370.
