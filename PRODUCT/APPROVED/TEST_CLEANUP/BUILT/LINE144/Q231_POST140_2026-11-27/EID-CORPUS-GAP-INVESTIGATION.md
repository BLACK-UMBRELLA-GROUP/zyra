# Line144 current-base Eid corpus gap investigation

This is a static explanation plus evidence from the first completed large375-2 artifact. It does not claim the final four-shard union failed: the root owner must inspect that actual union once all four artifacts arrive.

## Exact source reason

Accepted line142 commit `62b6293987cd4e601f1db921c42a4797addd8c9a` (27 Nov 15:44 UTC, LOCK47/Q230) added the seasonal offers routes after prepared candidate base `d4c25483`. Neither `eid_gift_preview` nor `ramadan_draw_preview` occurs in the shell at d4; both exist at accepted `34494380`. Line142 did not extend `zyra_clearer_text_corpus.dart`.

Current corpus imports and registration contain22 suites. They omit `test/visual/line142_offers_preview_test.dart`. A scoped scan of all22 imported fixture files finds no Eid/Ramadan or offer-choice fixture configuration. The existing line142 suite explicitly supplies `offerChoices: ZyraPreviewOfferChoices(eid: eid)` at line214 and taps `preview_open_eid_gift` at line217; this is the only test reference to that opener. Its five cases cover all four plans, including both Seeker One Eid variants.

`BaselineHarness.mount` defaults `offerChoices` to null and passes it through at baseline_capture_support.dart968/986. Shell `_offerChoices` (10354-10355) then uses developerSamples.offers. The sample state defaults/reset to `const ZyraPreviewOfferChoices()` (state/zyra_developer_samples.dart153/641), whose model defaults are Eid.none/Ramadan.false (models/zyra_offers_preview.dart28-32). `zyraEidGiftPreview` returns null for Eid.none. Shell `_seasonalOfferFocus` exposes the Eid opener only for nonnull `_eidGift` (10389-10399); `_offersView` also rejects null gifts (10419-10421). No registered fixture enables that input or invokes its opener, so the registered corpus has no actual Eid gift frames.

## Why the new obligation appears

The shell case at line3541 is `'eid_gift_preview' || 'ramadan_draw_preview' => _offersView()`. The corpus discovers expected routes dynamically from that shell. Its anchored regex captures the first quoted alternative on a line, so the current dynamically required route includes Eid. The second same-line Ramadan alternative is not separately discovered by that regex. This describes the current extractor, not permission to waive or add anything.

The route matrix does not classify Eid as Seeker-only or Guardian-only, so it requires all four plans. One missing current-route obligation plus four missing route/plan/viewport obligations are consequently expected. The first real large375-2 artifact honestly contains precisely those five Eid gaps. The single-shard report is complete but correctly claims only individual-shard scope.

## Boundary

This is a test-corpus registration gap on an accepted newer app base, not evidence of an app fault and not an app-colour issue. Clean patch/preimage hashes cannot detect a newly added route in another source file. Keep the obligations, existing assertions and artifact data. The root owner must decide only after measuring all four actual coverage reports; if the final union retains the gap, the current instructions call for one For Fable question and release, rather than an unapproved registration expansion or exclusion.
