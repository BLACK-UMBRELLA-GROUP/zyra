FEATURE NAME
PROFILE DECISION SYSTEM

============================================================
REFERENCES
============================================================

------------------------------------------------------------
References (depends on)
------------------------------------------------------------

Browse
- The Browser tab is the access point for profile decisions.
- Decline / Review / Consider buttons are accessible from Browse.
- Status: Referenced — definition lives in APP/Browse.

Subscriptions (User Features)
- Button access is gated by subscription tier (Basic, Pro, Premium).
- Review Count and Incoming Considerations are subscription features.
- Mutual Review Detection is a Premium-only feature.
- Status: Referenced — subscription definitions live elsewhere.
- ⚠️ OVERLAP FLAG: Subscription tier feature lists exist in both
  this file and the Subscriptions doc. Keep in sync.

Communication System
- Controls communication permissions after a Match is created.
- Handles messaging pause when a Consideration is removed.
- Status: Referenced — definition lives elsewhere.

Family Introduction System
- Premium subscription includes Family Introduction Features.
- Family Introduction events are recorded in the Relationship Timeline.
- Status: Referenced — definition lives elsewhere.

Notifications System
- Review Count notifications sent to all tiers.
- Incoming Consideration notifications sent to Premium Seekers.
- Mutual Review Detection notifications sent to Premium Seekers.
- Consideration removal notifications sent to affected Seeker.
- Match creation notifications sent to both Seekers.
- Status: Referenced — definition lives in APP/Notifications.

------------------------------------------------------------
Referenced By
------------------------------------------------------------

Browse
- Hosts the Decline / Review / Consider buttons.

Communication System
- Depends on Match creation and Consideration status.

Notifications
- Receives events from this system to trigger notifications.

Timeline
- Relationship Timeline is owned and populated by this system.

Family Introduction System
- Uses Match and Consideration status as prerequisites.

------------------------------------------------------------
USER-FACING TERMINOLOGY MAP
------------------------------------------------------------

| User Sees              | System Uses              |
|------------------------|--------------------------|
| Decline                | Declined                 |
| Review                 | Reviewed Profiles        |
| Consider               | Considerations           |
| Consideration          | Considerations           |
| Mutual Review          | Mutual Review Detection  |
| Mutual Consideration   | Mutual Consideration     |
| Match                  | Match                    |
| Timeline               | Relationship Timeline    |

------------------------------------------------------------
Open Dependencies
------------------------------------------------------------

- Communication System rules post-Match not fully defined here.
- Family Introduction System prerequisites not fully defined here.
- Wali subscription access to profile decisions not specified.
- Whether declined profiles can be re-discovered not specified.
