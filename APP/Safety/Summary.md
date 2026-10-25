---
id: DOC-ZYRA-0058
type: SPEC
status: CURRENT
feature: APP: SAFETY
purpose: Safety — Summary: SAFETY — RATE LIMITING & COOLDOWN SYSTEM: Protect the platform from abuse, spam, bots, and excessive usage while minimising impact on genuine users.
links: []
owner: ZYRA chat
---

FEATURE NAME
SAFETY — RATE LIMITING & COOLDOWN SYSTEM
Group: 5 — Application Architecture

============================================================
SUMMARY
============================================================

Purpose:
Protect the platform from abuse, spam, bots, and excessive
usage while minimising impact on genuine users.

Design Philosophy:
Normal users should rarely experience restrictions.
Restrictions increase progressively as suspicious behaviour
increases. The goal is to slow, identify, and stop abuse
while protecting the experience of genuine users.

------------------------------------------------------------
MONITORED ACTIVITIES
------------------------------------------------------------

• Likes
• Profile Views
• Messages
• Searches
• Login Attempts
• Password Resets
• AI Requests
• Uploads
• Verification Requests

------------------------------------------------------------
PROGRESSIVE RESPONSE SYSTEM
------------------------------------------------------------

Level 1 — Warning
  Suspicious activity detected.
  User receives a warning. No restriction yet.

Level 2 — Temporary Cooldown
  Trigger: Excessive activity continues after warning.
  Action: 30-second lock.

Level 3 — Extended Cooldown
  Trigger: Activity continues after Level 2.
  Action: 5-minute lock.

Level 4 — Security Review
  Trigger: Persistent suspicious behaviour.
  Action: Additional verification required.
  Restrictions applied. Account placed under monitoring.

Level 5 — Temporary Suspension
  Trigger: Behaviour unresolved through Levels 1–4.
  Action: Account review required before reinstatement.

------------------------------------------------------------
ABUSE PROTECTION GOAL
------------------------------------------------------------

• Slow abuse.
• Identify abuse.
• Stop abuse.
• Protect genuine users.

============================================================
APPROVED TO-DO LIST
============================================================

• Define specific thresholds for each monitored activity
  that trigger each level (exact counts, time windows).
• Design the warning notification message shown to the user.
• Define the verification method used at Level 4.
• Define the account review process for Level 5.
• Determine whether different activity types use different
  thresholds (e.g. login attempts vs message volume).
• Decide how quickly levels reset after compliant behaviour.
