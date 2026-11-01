---
id: TBC (Fable assigns)
type: SPEC
status: ARCHIVED (2026-10-31)
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 16 - blocking or hiding someone you are in a Journey with ends the Journey, after a warning
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BLOCK / HIDE DURING A JOURNEY — SPEC — V1 (LOCKED 31 OCT 2026)

Seeker One and Seeker Basic. Masters (430 × 932 @3x, Ivory, prototype V98) in `../MASTERS/`: b01 block_confirm · b02 hide_confirm ·
b03 journey_tab_after.

## Rule (Founder 31 Oct: "Hide ends the Journey")

Blocking **or hiding** a person you are in a current Journey with **ends that Journey first**, after a warning. Blocking or hiding
someone you are not in a Journey with is unchanged (no sheet).

## Where

Every Block or Hide entry point for that person: Report profile (Hide profile / Block profile links, reached from Journey options →
Report, View profile → Report, Profiles ••• → Report) and any other Hide/Block button the app has for a person.

## Confirm sheet (bottom sheet over a dimmed page; tapping the dim area = Keep)

| Part | Block | Hide |
|---|---|---|
| Title | "Block Sara and end your Journey?" | "Hide Sara and end your Journey?" |
| Line | "You're in a Journey with Sara. Blocking ends it first." | "You're in a Journey with Sara. Hiding ends it first." |
| Row 1 (chat icon) | "Your Journey ends" · "It ends for both of you and can't be reopened. Your Timeline stays." | same |
| Row 2 | (shield) "Sara is blocked" · "Sara can't see you, send you a request or message you again. Sara isn't told you blocked them." | (eye-off) "Sara is hidden" · "Sara won't appear in Profiles again. You can undo this in Settings → Hidden Profiles." |
| Buttons | "Keep this Journey" (outline) · "End Journey and block" (red text `#B84A42`, red border) | "Keep this Journey" · "End Journey and hide" |

Names are the person's first name. The two rows sit in one floating card like the End Journey page.

## After confirming

1. End the Journey with the existing end-Journey action (same effect as End Journey: ends for both, Timeline kept, place freed).
2. Then block / hide with the existing action. If a report reason was chosen, the report is still sent.
3. Go to the Journey tab (b03) and show the toast "Your Journey with Sara has ended and Sara is blocked." / "Your Journey with Sara has ended. Sara won't appear again."

## Text changes elsewhere (today's app says hiding never ends a Journey)

| Where | Today | New |
|---|---|---|
| Settings → Hidden Profiles, intro line | "These profiles are hidden from your view. Hiding does not block them or end a Journey." | "These profiles are hidden from your view. Hiding does not block them. Hiding someone you're in a Journey with ends that Journey." |
| Unhide sheet body | "This profile may appear for you in Profiles again. This does not change blocks or Journeys." | "This profile may appear for you in Profiles again. This does not change blocks or bring back an ended Journey." |
