FEATURE NAME
PROFILE DECISION SYSTEM
Group: 4 — Page Responsibilities

============================================================
SUMMARY
============================================================

Purpose:
Defines the profile decision system used by Seekers after
viewing marriage profiles.

Owns:
- Decline / Review / Consider
- Reviewed Profiles
- Considerations
- Incoming Considerations
- Match Creation
- Mutual Review Detection
- Review Count Notifications
- Relationship Timeline

------------------------------------------------------------
TERMINOLOGY
------------------------------------------------------------

Seeker
- The person searching for marriage.
- The primary user making profile decisions.
- Holds a Seeker subscription (Basic, Pro or Premium).

Wali
- The Seeker's appointed supervisor.
- Provides guidance and oversight throughout the marriage process.
- Holds a Wali subscription (Wali, Wali Pro or Wali Gold).
- May assist with profile discovery depending on their subscription.
- Does not replace the Seeker's decisions.

------------------------------------------------------------
BUTTONS
------------------------------------------------------------

🔴 Decline
- Profile is declined.
- Discovery moves to the next profile.

🟡 Review
- Profile is added to Reviewed Profiles.
- Used for profiles the Seeker wants to review later.
- Does not create a Consideration.
- Does not create a Match.

🟢 Consider
- Profile is added to Considerations.
- Indicates the profile may be suitable for marriage consideration.
- Does not mean "like", "love", or "match".

------------------------------------------------------------
BUTTON ACCESS
------------------------------------------------------------

Basic Seeker
- 🔴 Decline
- 🟡 Review

Pro Seeker
- 🔴 Decline
- 🟡 Review
- 🟢 Consider

Premium Seeker
- 🔴 Decline
- 🟡 Review
- 🟢 Consider

------------------------------------------------------------
LISTS
------------------------------------------------------------

Reviewed Profiles
- Private review list.
- Profiles the Seeker wants to revisit later.
- Maximum 50 profiles in Review.
- Users can remove profiles from Review at any time.
- Removing a profile immediately frees a Review slot.
- When the Review list reaches 50 profiles, users must remove
  a profile before adding another profile to Review.
- Review counter displayed.
Examples:
0/50 In Review
23/50 In Review
48/50 In Review
50/50 In Review

Considerations
- Profiles the Seeker believes may be suitable for marriage consideration.
- Separate from Reviewed Profiles.
- Users can remove profiles from Considerations at any time.
- Considerations are visible to Premium Seekers through Incoming Considerations.

Incoming Considerations
- Shows active Seekers who have placed your profile under Consideration.
- Removed Considerations no longer appear.

Matches
- Created through Mutual Consideration.
- Match creation does not automatically grant communication access.

------------------------------------------------------------
REVIEW COUNT FEATURE
------------------------------------------------------------

Basic
- Receives Review Count notifications.
- Cannot see who reviewed them.
Example: "7 people have added your profile to Review."

Pro
- Receives Review Count notifications.
- Cannot see who reviewed them.
Example: "12 people have added your profile to Review."

Premium
- Receives Review Count notifications.
- Can see Incoming Considerations.
- Does not need to find the profile first.

------------------------------------------------------------
MATCH CREATION
------------------------------------------------------------

A Match is created when:
- Seeker A considers Seeker B.
- Seeker B considers Seeker A.

Result:
- Mutual Consideration created.
- Match created.
- Both Seekers notified.
- Wali approval is not required for Match creation.
- Communication permissions are controlled by the Communication System.

------------------------------------------------------------
PREMIUM FEATURE – MUTUAL REVIEW DETECTION
------------------------------------------------------------

Premium Seekers receive access to Mutual Review Detection.

A Mutual Review occurs when:
- Seeker A reviews Seeker B.
- Seeker B reviews Seeker A.

Mutual Review Detection only occurs when BOTH Seekers have
an active Premium subscription.

Examples:
Premium + Premium = Mutual Review Detection Active
Premium + Pro     = No Mutual Review Detection
Premium + Basic   = No Mutual Review Detection
Pro + Pro         = No Mutual Review Detection
Basic + Basic     = No Mutual Review Detection

When two Premium Seekers have reviewed each other, ZYRA
detects the Mutual Review and notifies both Seekers.

Notification:
"A profile you reviewed has also reviewed your profile.
Would you like to move this profile to Consideration?"

Options:
- Move to Consideration
- Keep in Review

If both Seekers choose Move to Consideration:
- Mutual Consideration created.
- Match created.

If one Seeker chooses Move to Consideration and the other
chooses Keep in Review:
- No Match is created.
- The profile remains in Review for the other Seeker.

If either Seeker is Basic or Pro:
- No Mutual Review Detection occurs.
- No notification is sent.
- No prompt is shown.
- Profiles remain in their respective Review lists.

------------------------------------------------------------
CONSIDERATION REMOVAL
------------------------------------------------------------

When a Seeker removes a Consideration:
- Their Consideration is removed.
- The other Seeker receives a notification.
- The event is recorded in the Relationship Timeline.
- The other Seeker may keep their own Consideration active.
- Future reconsideration is allowed unless the Seeker has been blocked.
- Communication permissions are handled by the Communication System.

------------------------------------------------------------
RELATIONSHIP TIMELINE
------------------------------------------------------------

Every profile interaction is recorded in a timeline.

Purpose:
- Relationship history.
- Transparency.
- Wali supervision.
- Support and moderation.
- Future family introduction tracking.

Example Timeline:
01 Jun  Seeker A reviewed Seeker B
03 Jun  Seeker B considered Seeker A
05 Jun  Seeker A considered Seeker B
05 Jun  Match created
12 Jun  Seeker B removed consideration
15 Jun  Seeker B reconsidered Seeker A
18 Jun  Messages started
22 Jun  Seeker B removed consideration
22 Jun  Messaging paused

------------------------------------------------------------
TIMELINE EVENTS
------------------------------------------------------------

- Review Added
- Review Removed
- Consideration Added
- Consideration Removed
- Match Created
- Match Ended
- Messages Started
- Messages Paused
- Wali Added
- Wali Removed
- Family Introduction Requested
- Family Introduction Accepted

------------------------------------------------------------
TIMELINE ACCESS
------------------------------------------------------------

Seeker  — Can view their own relationship timelines.
Wali    — Can view timelines they supervise.
Admin   — Can view timelines for support, moderation and dispute resolution.

------------------------------------------------------------
PHILOSOPHY
------------------------------------------------------------

🔴 Decline  = This profile is not suitable for me.
🟡 Review   = I would like to review this profile later.
🟢 Consider = This profile may be suitable for marriage consideration.

A Match occurs only when both Seekers choose Consider.
Reviewing profiles is a private action.
The system is designed around suitability, consideration and
progression rather than likes, hearts or dating-style matching.

------------------------------------------------------------
SUBSCRIPTION ALIGNMENT
------------------------------------------------------------

Basic
- Decline
- Review
- Review Count Notifications
- 50 Profiles in Review

Pro
- Decline
- Review
- Consider
- Review Count Notifications
- 50 Profiles in Review

Premium
- Decline
- Review
- Consider
- Review Count Notifications
- See Incoming Considerations
- Mutual Review Detection
- Family Introduction Features
- 50 Profiles in Review

============================================================
APPROVED TO-DO LIST
============================================================
(None listed in source — add as decisions are made.)
