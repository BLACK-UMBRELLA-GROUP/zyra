// Protected sample wrapper for the shared Portrait Browse presentation.
// Only in-memory data:image references may reach its image widget. No member
// lookup, services or persistence lives here.
import 'package:flutter/material.dart';

import '../models/seeker_profile.dart';
import '../theme/zyra_interaction_style.dart';
import '../widgets/zyra_browse_designs.dart';
import '../widgets/zyra_browse_next_photo_motion.dart';
import '../widgets/zyra_profile_image.dart';

export '../widgets/zyra_browse_designs.dart' show ZyraOneJourneyBrowseDesign;

Widget _samplePhoto(
  BuildContext context,
  String photo, {
  required double width,
  required double height,
  required Alignment alignment,
}) => ZyraProfileImage(
  photo.startsWith('data:image/') ? photo : '',
  width: width,
  height: height,
  alignment: alignment,
);

/// Previous/Next are neutral navigation, never Pass or Dislike. The caller
/// owns local sample eligibility and actions; the Portrait layout stays shared.
class ZyraOneJourneyBrowseDesigns extends StatefulWidget {
  const ZyraOneJourneyBrowseDesigns({
    super.key,
    required this.profiles,
    required this.selectedIndex,
    required this.design,
    this.showFeedChrome = true,
    this.onPrevious,
    this.onNext,
    this.onFilters,
    this.onBrowseMenu,
    this.onProfile,
    this.onRequest,
    this.requestLabel,
    this.requestSemanticLabel,
    this.invitationSent,
    this.canRequest,
    this.bottomPadding = 100,
    this.photoBuilder,
    this.alignHeaderActions = false,
    this.nextProfileMotion = ZyraBrowseNextMotion.current,
    this.nextProfileMotionEpoch = 0,
    this.hapticLevel,
    this.initialPhotoIndices = const <String, int>{},
    this.onPhotoIndexChanged,
    this.initialGalleryIndices = const <String, int>{},
    this.onGalleryIndexChanged,
  });

  final List<SeekerProfile> profiles;
  final int selectedIndex;
  final ZyraOneJourneyBrowseDesign design;
  // Presentation only; the shared gallery and offline source guard are unchanged.
  final bool showFeedChrome;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onFilters;
  final ValueChanged<SeekerProfile?>? onBrowseMenu;
  final ValueChanged<SeekerProfile>? onProfile;
  final ValueChanged<SeekerProfile>? onRequest;
  final String Function(SeekerProfile)? requestLabel;
  final String Function(SeekerProfile)? requestSemanticLabel;
  final bool Function(SeekerProfile)? invitationSent;
  final bool Function(SeekerProfile)? canRequest;
  final double bottomPadding;

  /// Optional owner-prepared offline renderer. The existing sample-only
  /// default remains unchanged for existing callers and fixtures.
  final ZyraBrowsePhotoBuilder? photoBuilder;
  final bool alignHeaderActions;
  final ZyraBrowseNextMotion nextProfileMotion;
  final int nextProfileMotionEpoch;
  final ZyraHapticLevel? hapticLevel;
  // Legacy actual-photo ordinals retain their numbering in either layout.
  final Map<String, int> initialPhotoIndices;
  final void Function(String, int)? onPhotoIndexChanged;
  // Gallery seeds use the selected layout. An explicit seed takes precedence.
  final Map<String, int> initialGalleryIndices;
  final void Function(String, int)? onGalleryIndexChanged;

  @override
  State<ZyraOneJourneyBrowseDesigns> createState() =>
      _ZyraOneJourneyBrowseDesignsState();
}

class _ZyraOneJourneyBrowseDesignsState
    extends State<ZyraOneJourneyBrowseDesigns> {
  Widget _photo(
    BuildContext context,
    String source, {
    required double width,
    required double height,
    required Alignment alignment,
  }) => (widget.photoBuilder ?? _samplePhoto)(
    context,
    source.startsWith('data:image/') ? source : '',
    width: width,
    height: height,
    alignment: alignment,
  );

  @override
  Widget build(BuildContext context) => ZyraBrowseDesigns(
    profiles: widget.profiles,
    selectedIndex: widget.selectedIndex,
    design: widget.design,
    showFeedChrome: widget.showFeedChrome,
    photoBuilder: _photo,
    onPrevious: widget.onPrevious,
    onNext: widget.onNext,
    onFilters: widget.onFilters,
    onBrowseMenu: widget.onBrowseMenu,
    onProfile: widget.onProfile,
    onRequest: widget.onRequest,
    requestLabel: widget.requestLabel,
    requestSemanticLabel: widget.requestSemanticLabel,
    invitationSent: widget.invitationSent,
    canRequest: widget.canRequest,
    bottomPadding: widget.bottomPadding,
    alignHeaderActions: widget.alignHeaderActions,
    nextProfileMotion: widget.nextProfileMotion,
    nextProfileMotionEpoch: widget.nextProfileMotionEpoch,
    hapticLevel: widget.hapticLevel,
    initialPhotoIndices: widget.initialPhotoIndices,
    onPhotoIndexChanged: widget.onPhotoIndexChanged,
    initialGalleryIndices: widget.initialGalleryIndices,
    onGalleryIndexChanged: widget.onGalleryIndexChanged,
  );
}
