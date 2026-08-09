FEATURE NAME
Compatibility Unlocks (Name TBC)

============================================================
FLOW DIAGRAM
============================================================

------------------------------------------------------------
Entry Points
------------------------------------------------------------

Seeker is viewing a profile that is Saved or Considered
→ "Unlock" or "Unlock+" button shown on profile card

Blocked entry points:
  • Cannot unlock while swiping
  • Cannot unlock on passed profiles
  • Profile must be Saved or Considered first

(Corrected 2026-07-12, DR-076 — was "Review or Consider". Renamed
again 2026-07-25, DR-ZYRA-099 terminology sweep-miss — Declined/
Liked -> Passed/Considered.)

------------------------------------------------------------
Purchase Flow
------------------------------------------------------------

Seeker has no credits
→ Purchase screen shown
   Pricing (Founder approved 2026-08-03): 1 Unlock = £1.99 / 5 Unlocks = £7.99
→ Seeker selects quantity
→ Payment confirmed
→ Credit applied to account

Seeker already has credits
→ Credit deducted immediately
→ Proceed to result

Once used:
→ Profile permanently unlocked for that Seeker
→ No repurchase required to view again

------------------------------------------------------------
Result Delivery
------------------------------------------------------------

Compatibility Unlock
→ High-level overview shown
   - Overall Compatibility %
   - Green / Yellow / Red counts

Compatibility Unlock+
→ Detailed breakdown shown
   - Overall Compatibility %
   - Green / Yellow / Red counts
   - Category scores (categories TBC)

------------------------------------------------------------
Progression Paths
------------------------------------------------------------

Path A — Pre-match purchase
→ Seeker buys Unlock or Unlock+
→ Views result
→ Decides whether to continue matching journey

Path B — Post-match (TBC — pending review)
→ Seeker completes normal matching journey
→ Successful match occurs
→ Unlock+ availability post-match to be confirmed

------------------------------------------------------------
Boundaries
------------------------------------------------------------

• Seeker only — Guardian cannot purchase or use unlocks
• Never reveals profile photos
• Never bypasses privacy settings
• Does not reveal individual questions or answers
• Does not reveal which specific questions are Green, Yellow or Red
