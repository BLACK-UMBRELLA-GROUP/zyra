# ZYRA roadmap

**Overall:** roughly **400 hours** of work remain to launch (server rules and real data, Android, safety and consent, onboarding, purchases, the full test suite back to green, store release). The table below is the first slice, drawn from the open actions and build queue.

ZYRA is pre-launch. This is an estimate of the next 26 hours of work from the open actions and build queue, not an approval to start new implementation. Each item needs the Founder's direction and any required locked designs. Actual effort may change when the checks expose more work.

| Work | Estimated hours | Intended result |
| --- | ---: | --- |
| Server rules and real data | 8 | Implement the approved server-rules specification, connect the new interface to real member data, and check permissions and state changes. The current Founder preview still uses sample data. |
| Android build preparation | 3 | Check the Android project and build route, record any blockers, and prepare a testable build when authorised. |
| Safety and consent | 4 | Complete the approved safety and consent screens, check guardian-sharing privacy, and reconcile wording with the legal and safety review before launch. Terms and purchase wording need review before purchases become available. |
| Onboarding tour | 3 | Implement or complete the tour from locked designs and check the empty, loading and error paths around onboarding. |
| Test baseline and final interface pass | 6 | Triage the existing failing baseline, agree the repairs, and run the required checks after those approved changes. The last full run recorded 649 failure/error records across 91 files. Remove Developer Access controls only after the other interface work is complete, as the queue requires. |
| Documentation and handover | 2 | Update setup instructions, record checked versions and limitations, and prepare the as-built handover for review. |

The private legal review covers member terms, data protection, safety response and online safety duties. Those actions, the real-data connection and purchase wording remain launch dependencies. Repository preparation does not make the app ready for members or authorise publishing the repository.

Source of this plan: the project's open-actions register, `PRODUCT/APPROVED/BUILD_QUEUE.md`, and the approved public-repository brief. Progress and approvals remain in those records.
