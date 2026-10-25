---
id: DOC-ZYRA-0036
type: SPEC
status: CURRENT
feature: APP: ONBOARDING
purpose: Onboarding / Profile Completion — Summary: The Profile Completion Stage begins immediately after onboarding.
links: []
owner: ZYRA chat
---

FEATURE NAME
PROFILE COMPLETION
Group: 4 — Page Responsibilities

CURRENT PROGRESSIVE ENTRY / FINAL REVIEW — 2026-10-02
Founder-approved current flow supersedes the historical sequence below:
account essentials → mandatory identity verification → Continue profile setup
or enter My ZYRA and finish later → Your Profile / optional Journey Bio /
Compatibility / Review & go live. Account admission is not profile publication.
An unfinished Seeker profile stays hidden; Discovery/Journeys remain gated.

The final review reads actual saved profile fields (including three photos),
existing server compatibility progress and identity state. It never marks a
profile complete merely because the page was visited. Go live is explicit,
rechecked and confirmed by the existing server RPC; failed or uncertain
confirmation remains a retry/recovery state, not a success message. Bio prose
is optional. Review choices uses the existing profile editor, with strict
owner-bound restore/save. DOB/gender are fixed with account essentials, not
with first publication. My ZYRA remains an explicit safe exit.

No production IDV provider, database policy, membership activation or new
compatibility calculation is implemented by this client cleanup. As-built,
verification and open safety gates: Onboarding Preview handover §89;
OA-ZYRA-303, linked OA-ZYRA-193/266. Founder acceptance remains separate.

============================================================
SUMMARY
============================================================

Purpose:
The Profile Completion Stage begins immediately after
onboarding. Rather than sending users straight into
Discover, ZYRA gives them the opportunity to complete and
review their profile before it becomes visible to
potential matches.

Designed to improve profile quality while creating a clear,
intentional transition between onboarding and discovering
people.

------------------------------------------------------------
FLOW
------------------------------------------------------------

Onboarding Complete
        ↓
Profile Completion
        ↓
Review Profile
        ↓
Profile Ready
        ↓
Enter Discover

------------------------------------------------------------
OBJECTIVES
------------------------------------------------------------

• Encourage users to finish setting up their profile.
• Improve first impressions for other users.
• Reduce incomplete profiles in Discover.
• Allow users to review their information before
  becoming visible.
• Make the transition into the app feel intentional
  rather than abrupt.

------------------------------------------------------------
PROFILE COMPLETION SCORE
------------------------------------------------------------

A completion indicator is displayed throughout this stage.

Example:
  Profile Completion
  ████████░░ 80%
  4 of 5 tasks completed

The score updates instantly as tasks are completed.
Designed to motivate, not pressure.

------------------------------------------------------------
REQUIRED TASKS
------------------------------------------------------------

• Add your name (if not already provided).
• Upload your first profile photo.
• Review your profile information.
• Confirm your profile is ready.

------------------------------------------------------------
OPTIONAL TASKS (Future Discussion)
------------------------------------------------------------

• Add additional profile photos.
• Write a short biography.
• Preview how your profile appears to others.
• Complete optional profile sections.
• Learn how matching works.
• Receive AI-powered profile suggestions.
• Improve profile completion score.

------------------------------------------------------------
REVIEW PROFILE
------------------------------------------------------------

Before entering Discover, users can review their complete
profile exactly as other users will see it.

This final review allows users to:
• Check profile photos.
• Check profile information.
• Make final edits before becoming visible.
• Enter Discover with confidence.

------------------------------------------------------------
PROFILE READY
------------------------------------------------------------

Once all required tasks are complete, the profile is
marked as Profile Ready.

Users receive a final confirmation before entering Discover.

Example:
  ✓ Your profile is ready.
  You're now ready to discover people with your best
  first impression.

------------------------------------------------------------
IMPORTANT NOTE
------------------------------------------------------------

Profile Completion is simply the final step before
entering Discover.

Nothing chosen during onboarding or profile completion
is permanent.

Users can update their profile photos, biography,
personal information, preferences, interests, visibility
settings, and other profile details at any time from
Settings → Edit Profile.

The goal is simply to ensure every user starts Discover
with a complete, high-quality profile, knowing they can
continue improving it whenever they like.

------------------------------------------------------------
DESIGN PRINCIPLES
------------------------------------------------------------

• Should feel encouraging rather than like another form.
• Progress should always be visible.
• Tasks should be simple, rewarding, and easy to complete.
• Users should understand why each task improves their
  profile.
• Profile quality should be the focus, not task completion.
• Completion should naturally lead into Discover.

------------------------------------------------------------
FUTURE ENHANCEMENT — AI PROFILE REVIEW
------------------------------------------------------------

After profile completion, ZYRA's AI can privately evaluate
profile quality (photos, bio, completeness, clarity, etc.)
and provide improvement suggestions.

These recommendations are visible only to the profile owner
and are intended to help users create stronger first
impressions without affecting how others view their profile.

============================================================
APPROVED TO-DO LIST
============================================================

• Define the exact list of required vs optional tasks.
• Design the completion score UI.
• Design the profile preview (how it appears to others).
• Define AI profile review scope and suggestions format.
• Determine when the profile becomes visible in Discover
  (on Profile Ready confirmation, or immediately after
  onboarding?).
