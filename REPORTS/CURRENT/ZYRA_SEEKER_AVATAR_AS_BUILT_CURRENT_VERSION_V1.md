---
id: AS-BUILT-ZYRA-LINE104
type: HANDOVER
status: CURRENT
feature: PROFILE TAB
purpose: As-built handover for photo one in Seeker avatars
links: [DOC-ZYRA-0418, DOC-ZYRA-0419, AD-AIOS-115, OA-ZYRA-317]
owner: Codex
---

# Seeker photo one

Queue line 104 follows PROFILE_TAB V4 §7, the 12 November Founder instruction
in the Profile LOCK record and archived prototype V222. The prototype uses
the Seeker's own photo in both Circle views. The app retains its existing
avatar sizes and uses the Profile silhouette whenever photo one is unavailable.
Guardian Profile and Circle retain their existing monogram treatment.

| Entry | As built |
|---|---|
| Profile and Preview | The Founder account tab and ordinary Profile header use the shared photo and saved crop. The opening Preview card uses the shared avatar inside the existing Profiles component at that card's existing crop. Gallery pages retain their existing photo controls. |
| Guardian Circle | The Founder Circle menu shows the same Seeker photo to the Seeker and linked Guardian. Ordinary Circle members and Read by use the shared avatar when the existing Circle gate admits the route. Message bubbles in either layout have no sender portrait. |
| Journey, Timeline and chat | Founder Journey confirmation portraits and the Journey options page use the avatar. The ordinary Journey confirmation and partner portrait, Timeline milestone confirmation, and one-to-one chat header and Read by sheet use it. Timeline stage markers and the Seeker My ZYRA greeting have no identity portrait. |
| Guardian's Seeker views | Founder Seekers roster, Seeker detail and the Guardian Journey identity card use photo one. The ordinary Guardian My ZYRA profile card, Seekers roster and linked workspace do the same. An unrelated Network identity keeps its existing rendering and access. |

`SOURCE/lib/widgets/zyra_seeker_avatar.dart` renders the round photo and
silhouette. Founder surfaces read the protected shell's local account session.
Ordinary owner surfaces use the first slot in `AppState`, hydrated through
`ZyraSessionRouter` and `ZyraPhotoService` and refreshed by Edit Photos. The
ordinary viewer paths use existing profile reads and the narrow first-photo
projection in `ZyraDiscoveryService`. Missing or unsignable photo one renders
the silhouette. Later gallery entries remain separate. Photo changes reach
the editing account through its existing state notification. Other viewers
get the current first slot on the surface's next normal read under existing
account and relationship access.

The app's Circle rollout gate remains closed. Live service behavior was
checked with local mocks and the Circle screens with detached fixtures.
Existing profile and storage permissions decide whether a linked viewer
can receive a photo. No migration, backend action, deployment or phone build
is part of this line. Fable and the ZYRA design chat retain handover review.

Evidence and verification commands are filed under
`REPORTS/EVIDENCE/LINE104_2026-11-12/` and in the line 104 task note.
The two Guardian Seeker detail test baselines in `SOURCE/test/visual/approved/queue75/`
reflect the §7 silhouette. The pixel comparison confines each change to its
avatar.
