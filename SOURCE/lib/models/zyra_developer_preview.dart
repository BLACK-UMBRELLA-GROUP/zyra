// Disposable Founder-preview choices. These carry no account or server authority.
import 'package:flutter/foundation.dart';

import 'zyra_error_state.dart';
import 'zyra_offers_preview.dart';

enum ZyraDeveloperViewAs {
  seekerOne('Seeker One', guardian: false, places: 3),
  seekerBasic('Seeker Basic', guardian: false, places: 1),
  guardianOne('Guardian One', guardian: true, places: 3),
  guardianBasic('Guardian Basic', guardian: true, places: 1);

  const ZyraDeveloperViewAs(
    this.label, {
    required this.guardian,
    required this.places,
  });

  final String label;
  final bool guardian;
  final int places;
}

enum ZyraProfileSmallPageSample {
  seekerOnly('Switch profile · Seeker only'),
  guardianOnly('Switch profile · Guardian only'),
  guardianNoSeekers('Your places · no Seekers yet');

  const ZyraProfileSmallPageSample(this.label);
  final String label;
}

enum ZyraDeveloperPreset {
  allCaughtUp('All caught up'),
  typicalDay('Typical day'),
  newMember('New member'),
  everything('Everything');

  const ZyraDeveloperPreset(this.label);
  final String label;
}

@immutable
class ZyraDeveloperPreviewValues {
  const ZyraDeveloperPreviewValues({
    required this.viewAs,
    required this.realPlanName,
    required this.journeyPlaces,
    this.canActivate = true,
    this.setupAvailable = true,
    this.signupAvailable = false,
    this.unverified = false,
    this.setupUnfinished = false,
    this.journeys = const [],
    this.selectedJourneyId,
    this.preset,
    this.notice = 0,
    this.offers = const ZyraPreviewOfferChoices(),
  }) : assert(notice >= 0 && notice <= 6),
       assert(journeyPlaces >= 0 && journeyPlaces <= 3);

  final ZyraDeveloperViewAs? viewAs;
  final String realPlanName;
  final int journeyPlaces;
  final bool canActivate, setupAvailable, signupAvailable;
  final bool unverified, setupUnfinished;
  final List<({String id, String name, String stage})> journeys;
  final String? selectedJourneyId;
  final ZyraDeveloperPreset? preset;
  // 0: none, 1–5: email preview, 6: Welcome back.
  final int notice;
  final ZyraPreviewOfferChoices offers;
}

/// The owning preview supplies already-guarded local actions. This value does
/// not grant access; the title host and the owner retain that responsibility.
class ZyraDeveloperPreviewActions {
  const ZyraDeveloperPreviewActions({
    required this.onViewAs,
    this.onStartSignup,
    required this.onUnverified,
    required this.onSetupUnfinished,
    required this.onJourney,
    required this.onStage,
    required this.onPreset,
    this.onProfileSmallPage,
    required this.onNotice,
    required this.onError,
    this.onRetentionMode,
    this.onEid,
    this.onRamadan,
  });

  final ValueChanged<ZyraDeveloperViewAs> onViewAs;
  final VoidCallback? onStartSignup;
  final ValueChanged<bool> onUnverified, onSetupUnfinished;
  final ValueChanged<String> onJourney, onStage;
  final ValueChanged<ZyraDeveloperPreset> onPreset;
  final ValueChanged<ZyraProfileSmallPageSample>? onProfileSmallPage;
  final ValueChanged<int> onNotice;
  final ValueChanged<ZyraErrorKind> onError;
  final ValueChanged<ZyraRetentionMode>? onRetentionMode;
  final ValueChanged<ZyraPreviewEid>? onEid;
  final ValueChanged<bool>? onRamadan;
}
