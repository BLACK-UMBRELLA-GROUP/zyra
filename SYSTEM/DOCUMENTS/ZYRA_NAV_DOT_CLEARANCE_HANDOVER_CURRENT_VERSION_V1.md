---
id: DOC-ZYRA-0231
type: HANDOVER
status: CURRENT
feature: NAVIGATION
purpose: ZYRA Navigation Dot Clearance Handover
links: []
owner: ZYRA chat
---

# ZYRA Navigation Dot Clearance Handover

**Version:** V1  
**Status:** CURRENT_VERSION — under-icon correction installed/native-launched with combined loading repair and POST-VERIFIED; Founder physical acceptance pending  
**Date:** 2026-10-18  
**Owner:** Codex under Founder authority; Founder accepts  
**Actions:** Existing OA-ZYRA-151/304; delivery OA-ZYRA-286/305  
**Authority:** Direct Founder screenshot request for smaller dots under every nav icon, clear of both glyph and selected gold circle; routine HOME delivery DR-ZYRA-257

## 1. Finding and selected correction

The Founder rejects the installed shoulder marker because it sits against the
selected gold circle. The earlier correction separated the dot from the glyph
but did not establish clearance from that circle's stroke. The new selection
supersedes that placement, not notification acknowledgement behaviour.

In the approved icon-only floating-glass nav, use a 4 × 4 logical-pixel dot,
centred under each unchanged 22 × 22 glyph. Its glyph-local bounds are
x9..13, y23..27: a 1-pixel gap below the glyph. The dot sits inside the gold
circle, clear of its border, rather than outside the whole circle where the
resting bar has insufficient comfortable room. With a centred resting 39.56px
circle and 1px inside stroke, radial clearance is 2.78px; the touched 46px
circle gives 6px. Tests must inspect actual animated ring bounds and stroke,
not only these target metrics. No icon/bar/circle size or centre is changed.

The explicit legacy showLabels API and developer-only Quiet Dot selection
comparison retain a smaller 4px shoulder marker at x24..28: y0..4 for labels,
y-4..0 for Quiet Dot. Moving it
under those alternate contents would introduce label/selection-marker clashes.
This compatibility guard is not a new selected nav design or a customer toggle.
All five tabs of the approved icon-only floating-glass design use the new
under-glyph placement in both selected and unselected states. A freely moving
circle may geometrically sweep past any fixed indicator between destinations;
do not claim perpetual stroke separation at arbitrary off-centre drag offsets.

All five icons retain their common 22-pixel size and centres. Cell/bar sizes,
selection halo, breathing/scrub behaviour, haptics, destinations, labels,
semantics and the numbered-badge branch remain unchanged. No dot suppression,
extra acknowledgement, persistence or notification read_at change is included.
The navigation Summary's missing Status and unrelated open dependencies are
not globally promoted: the direct Founder instruction authorises this one-off
bounded correction only.

## 2. Attention lifecycle retained

The protected preview projects current unacknowledged Received requests onto
the nav, dashboard lead and matching requests-area dots. Selecting My ZYRA alone
does not acknowledge them. Actually viewing the relevant Received destination
clears the matching visible items. Covered/stale/account/revision guards remain;
short and 15-minute restores retain awareness. Fresh/reset sample construction
intentionally creates new sample awareness. That fixture contract is unchanged.

Ordinary notification service/read_at behaviour is separate and unchanged.
Real-source integration remains OA-ZYRA-287; this local presentation correction
does not claim live notification readiness or public acceptance.

## 3. Source and evidence

Current packet
`SYSTEM/RESOURCES/REVIEWS/OA151_NAV_DOT_UNDERLINE_2026_10_18.w2v3g6`
captures true 4,824-input SOURCE_PRE, both runtime/test preimages and all three
document preimages before edits. SOURCE_PRE exactly equals installed
Bf1WZV SOURCE_POST. The intended delta remains only the shared nav runtime and
its existing geometry test; no new Source input or loading/auth change is added.
New checks and frames pass as recorded below. Build and same-phone delivery
are held for the later loading correction. Existing
OA151/304 own the refinement and OA286/305 its delivery. The separately
reproduced loading gap remains open under OA286/304/305 and is not repaired by
this marker task; Google remains paused with no sign-out.

### Previous shoulder correction evidence

Packet `SYSTEM/RESOURCES/REVIEWS/OA151_NAV_DOT_CLEARANCE_2026_10_18.Bf1WZV`
captures true SOURCE_PRE, the runtime preimage and Runbook/Index document
preimages before edits. Its 4,823-input PRE exactly equals installed
`OA151_CIRCLE_CLOSE_HINT_2026_10_18.U622ft/SOURCE_POST.json`.
The only intended Source changes are `lib/widgets/floating_nav_bar.dart` and
new `test/floating_nav_dot_clearance_test.dart`: 4,824 inputs after addition.

The new offline fixture measures the actual 7-pixel painted DecoratedBox rather
than its 15-pixel wrapper. Fifteen cases cover 320/393/430 widths, Browse/My ZYRA
selection, normal/reduced motion, dot-on/off icon stability, rounded-bar/cell
containment, real tap-down/mid-breath/scrub/release, tapping the dot centre,
exactly-once haptics/selection, numeric precedence and semantics. The pre-fix
393px Browse case captures its frame before asserting clearance, so an actual
overlap must fail. Optional captures are exclusive writes into a named existing
directory; no generated baseline is approved or written.

The existing three attention suites and floating-nav haptic suite preserve
clearing and interaction contracts. Final qualification must use fresh serial
analysis, six disjoint app groups (55 suites including the new fixture), recipe
controls, exact frame inventory/inspection, formatting, policy and index checks.
Failures remain immutable; a failed result is never promoted by narrative.

DOT_BEFORE genuinely fails on the painted overlap and preserves its old-state
frame. Initial DOT_FOCUS preserves 15 failures in the new fixture: a redundant
semantics handle disposed after the framework's leak check, plus exact global
Rect.size comparison affected by floating-point rounding at 393px. Remove only
that redundant handle (testWidgets already owns semantics) and use 0.001px
dimension tolerance. All geometric gap/overlap, semantics, containment, physical
gesture, haptic and state assertions remain. DOT_FOCUS_2 then passes 72 literal
cases across the five suites, with unchanged Source and owned recipes during
each run. No additional runtime change is made to address fixture defects.

Fresh frozen analysis is clean. The six disjoint groups pass 1,203 literal
app cases across exactly 55 suites: 169 startup, 187 wider-page, 327 navigation,
85 security, 161 profile/Browse and 274 chat/attention. There are zero failures,
skips or cancelled cases. Separate recipe controls pass 46. PRIMARY_SUITE_MANIFEST
asserts all configured/observed paths and distinct case identities; read-only
subagent review is an internal review, not approval or independent execution.

The two visual replays pass (15 geometry and nine existing attention cases,
overlapping the primary counts). All 24 expected images are opened by the
primary: 20 component frames and four real protected-shell attention frames.
The old frame shows the covering dot; corrected Browse/My ZYRA, motion, narrow
end shoulders and new/acknowledged frames show the intended separation/clearing.
VISUAL_INSPECTION binds exact names/hashes, RED receipt/frame and the 2px gap;
finalization now enforces that proof. Compact 200% shell frames retain their
scenario scroll positions; no whole-page redesign is inferred. Two-file
formatting has zero changes; process no-Git policy and 24 index tests pass.
Source and owned modules remain unchanged throughout final checks. Build,
native identity/device execution and Founder acceptance remain separate gates.

### 3.1 Exact build and native post-verification

`Bf1WZV/HOST_PROFILE.HRfvT1` builds successfully from 10:27:10.339 to
10:27:51.627 UTC on 18 October. Artifact SHA256:
`cfcd01369008a9e0bc856dfee76213ec6f67d01a805d5e9560e9a4698f5046b9`.
Plan SHA256:
`8de5a3830bc4325fe4665b0e037fcccdb802ac5335202df7dd8e014a19d93884`.
Source seal SHA256:
`7edbb64c74571c106294c9ecce0378211d2d427b924be4ce286b3d6a2bbeec1c`.
All 4,824 frozen inputs and 490 native pins remain bound. Exact post-build
verification passes 3,570 regular compiler inputs plus one declared absent
marker. Existing main ZYRA 1.0.0(5), iOS 15 identity/profile and strict deep
signatures pass. fullXcodeBuild=false: current Dart and freshly regenerated
objective_c on the measured retained main PROFILE host, not native-source repair.

The operator initially invokes the compiler postcheck with a relative BUILD
path, which the canonical-path guard rejects before compiler inventory work.
That failed receipt is preserved byte-for-byte as
`CALL_FAILURE/COMPILER_POSTCHECK.json`, SHA256
`99c09b8c590588490072336ab0d77af4e8fbef945ca9666145a2fa3b7e3f7238`.
COMPILER_CALL_FAILURE_RELOCATION records its original/corrected evidence path
and reason; the failed record is not rewritten or promoted. A separately timed
fresh inspection using the exact absolute BUILD path passes at 10:28:27.444 UTC.
No Source, owned recipe, compiler guard, build, signing or native requirement
changes to resolve this invocation mistake.

Fresh same-phone LOCK passes at 10:28:43.970 UTC, followed by exactly one
in-place INSTALL finishing 10:29:04.672 UTC. Native LAUNCH finishes
10:29:26.487 UTC. POST at 10:29:36.372 UTC confirms the exact installed app
container `C07C44BD-50A3-432A-BB8C-DEDE90529610` and PID 19431. Every stage
binds the same artifact, plan, source seal and paired device. HRfvT1 replaces
the installed U622ft/9btSP2 baseline; do not reinstall older candidates from
their stale unlock replies. Source/owned modules remain unchanged. Final
DELIVERED_AS_BUILT binds qualification, native chain and current documents.

The dot correction includes the unchanged preceding quiet-refresh, Back/edge,
own Browse preview and Circle close-text retirement. No app-data reset,
deliberate sign-out/Google test, upload, new trust/signing or backend operation
occurs. Native process verification is not a physical dot/loading acceptance.

### 3.2 Under icon refinement

The later selected-state screenshot rejects the shoulder position installed
above. w2v3g6 owns the new 4px under-glyph correction and full fresh
qualification. Its checked Source, artifact and delivery must not be inferred
from Bf1WZV/HRfvT1's earlier receipts. Those records remain historical evidence.
Fresh exact Source/recipe/compiler/artifact/identity and paired-phone gates
precede any new installation. Physical design acceptance remains with Founder.

Current DOT_BEFORE captures the installed shoulder and fails the first new size
assertion (expected 4px, actual 7px); it does not reach the ring assertion.
The primary separately opens that before frame and observes its ring-shoulder
contact. FOCUS_CURRENT preserves one actual compatibility failure: the labelled
nav's y-4 shoulder clips above the bar by 2.06px. All default-icon placement
cases pass. The bounded correction moves only the explicit labelled shoulder
to y0, keeping Quiet Dot at y-4 and the selected default under-glyph unchanged.
No bar/glyph/halo metrics are altered to address this finding under OA151/304.
The existing fixture now has 27 cases, including all five destinations at
320px in selected/inactive states, both motion preferences, real dot touches,
aligned breathing/full-size ring samples, exact callbacks/haptics, no-action
dot removal and explicit labelled/Quiet Dot compatibility. Optional captures
expect 32 nav frames plus four protected-shell attention frames.

FOCUS_CURRENT_2 passes 84 literal cases across the geometry, haptic and three
existing attention suites, zero failures/skips, with Source and owned recipes
unchanged during the run. CHECKED_PREBUILD then freezes exactly 4,824 inputs;
the final serial analyzer is clean and the six disjoint groups pass. Read-only
subagent review confirms exactly the two intended Source paths, the label-only
correction, and unchanged auth/loading inputs. This is internal verification,
not Founder approval or physical acceptance.

The fresh frozen groups pass 1,215 distinct literal app cases in exactly
55 disjoint suites: 169 startup, 187 wider-page, 327 navigation, 85 security,
161 profile/Browse and 286 chat/attention. There are zero failures/skips or
cancellations. PRIMARY_SUITE_MANIFEST binds their exact observed identities;
46 recipe controls pass separately. Overlapping visual replays pass 27 geometry
and nine attention cases. All 36 expected frames are individually opened by
the primary and bound by exact names/hashes in VISUAL_INSPECTION, including
all five selected/inactive positions, aligned motion samples and actual
protected-shell new/acknowledged states. Format checks show zero changes;
no-Git policy and 24 index tests pass. Source and owned modules remain frozen.
Written refusals retain the unrelated old labelled-circle/text layout,
numbered-badge paint and compact scenario scroll positions; no broad redesign
or arbitrary travelling-ring intersection guarantee is implied. The contained
build preflight is checked, but no dot-only build/install is executed. The
Founder now requires the subsequent loading repair before one combined update.

### 3.3 Combined loading repair qualification

`OA305_LOCKSCREEN_HANDOFF_2026_10_18.8nnkwr` carries the exact checked w2v3g6
Source as its original-time true PRE. Only four loading-coordination/fixture
paths change; both nav files remain byte-identical. The new frozen combined
candidate passes clean analysis, 1,236 distinct literal cases across 55 disjoint
suites, 46 recipe controls, zero-change format, policy and 24 index tests.
All 52 final frames are individually opened: the same 36 nav/attention frames
plus 16 loading handoff/recovery frames. No visual replay adds to the distinct
primary count. The exact seal, lineage, source ledger and phase manifests own
the combined qualification; older failed/partial diagnostics stay immutable.
Combined Mh96lJ builds successfully, with exact compiler/current-input proof
and existing main PROFILE identity/signature verified. Quiet Refresh Handover
§5 and the packet phase manifests bind the artifact/plan/seal. The first fresh
LOCK is negative (locked) and remains immutable. After one unlock request and
the Founder's “unlcked” reply, positive LOCK_2, one INSTALL, native LAUNCH and
exact POST pass by 12:31:09.735 UTC. Container
`C9AE4FB7-EA13-4A1B-B7D9-E158DFBD918A`, PID 19923, replaces HRfvT1 locally.
DELIVERED_AS_BUILT and true DELIVERY_DOC_PRE own final evidence. No rebuild,
app-data reset, sign-out, Google test or upload occurs. This is the combined
update, not a dot-only build or physical design/loading acceptance.

## 4. Delivery and acceptance boundaries

The Founder's later same-turn instruction explicitly holds iPhone updating
until the dot is correctly finished and the loading bug is then repaired.
Qualify and seal this dot-only candidate first; do not build/install it alone.
The loading continuation must take this checked Source as its true prestate,
preserve the dot correction and obtain fresh combined checks and native gates
before delivery. That combined chain is now completed in §3.3; HRfvT1 is the
previous installed baseline, not the current delivery target.

The Founder reports the 16-minute loading-check interval finished and explicitly
allows installation after checks. This does not say whether a loading flash
appeared: that physical result remains unreported. Google sign-in stays paused
before Q4 of the six-question round; earlier Q3 consent has not executed a
sign-out. No sign-out or Google testing belongs to this dot update.

The existing local HOME delivery rule, DR-ZYRA-257, applies only after fresh
qualification: current Dart and freshly regenerated objective_c on the measured
retained main PROFILE host, existing identity/profile/signatures, exact source,
recipe/compiler/artifact bindings, fresh same-phone unlock, install, native
launch and matching installed process. Full native-source repair remains held.
No upload, new trust/signing, app-data reset, backend/provider/migration,
purchase or public/live activation is authorised. Native post-verification is
not Founder visual/loading acceptance.

Shared registers remain ADMIN-owned and paused. A local UNSENT update attaches
this finding to the existing actions without allocating an identifier, sending
another chat a message, unpausing it or closing an action. BUILD → DOCUMENT →
TRACE → HANDOVER applies; current manifests own measured results and hashes.
