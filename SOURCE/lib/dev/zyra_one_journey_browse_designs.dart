// Protected sample wrapper for the shared Portrait Browse presentation.
// Only in-memory data:image references may reach its image widget. No member
// lookup, services or persistence lives here.
import 'package:flutter/material.dart';

import '../models/seeker_profile.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_interaction_style.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_browse_designs.dart';
import '../widgets/zyra_browse_next_photo_motion.dart';
import '../widgets/zyra_profile_image.dart';
import '../widgets/zyra_profile_video_player.dart';
import '../widgets/zyra_tap_feedback.dart';

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
  fit: BoxFit.cover,
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
    this.requestRowLabels,
    this.profileSwipe,
    this.bottomPadding = 100,
    this.fixedTabFooter = false,
    this.photoBuilder,
    this.alignHeaderActions = false,
    this.nextProfileMotion = ZyraBrowseNextMotion.current,
    this.nextProfileMotionEpoch = 0,
    this.hapticLevel,
    this.initialPhotoIndices = const <String, int>{},
    this.onPhotoIndexChanged,
    this.initialGalleryIndices = const <String, int>{},
    this.onGalleryIndexChanged,
    this.profileVideo,
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
  final List<String>? requestRowLabels;
  final ZyraProfileSwipe? profileSwipe;
  final double bottomPadding;
  final bool fixedTabFooter;

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
  final ZyraProfileVideoPlayback? profileVideo;

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
    requestRowLabels: widget.requestRowLabels,
    profileSwipe: widget.profileSwipe,
    bottomPadding: widget.bottomPadding,
    fixedTabFooter: widget.fixedTabFooter,
    alignHeaderActions: widget.alignHeaderActions,
    nextProfileMotion: widget.nextProfileMotion,
    nextProfileMotionEpoch: widget.nextProfileMotionEpoch,
    hapticLevel: widget.hapticLevel,
    initialPhotoIndices: widget.initialPhotoIndices,
    onPhotoIndexChanged: widget.onPhotoIndexChanged,
    initialGalleryIndices: widget.initialGalleryIndices,
    onGalleryIndexChanged: widget.onGalleryIndexChanged,
    profileVideo: widget.profileVideo,
  );
}

class ZyraBrowseBackUpgradeSheet extends StatelessWidget {
  const ZyraBrowseBackUpgradeSheet({
    super.key,
    required this.onUpgrade,
    required this.onDismiss,
  });

  final VoidCallback onUpgrade;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Material(
    color: ZyraColors.cardSurface,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
    clipBehavior: Clip.antiAlias,
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0x2E3E2E1E),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ZyraColors.journeyGold.withValues(alpha: .6),
                  ),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: ZyraColors.journeyGold,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Going back comes with Seeker One',
              textAlign: TextAlign.center,
              style: ZyraText.heading(
                size: 21,
              ).copyWith(fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 8),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  'Seeker Basic shows each profile once. With Seeker One you '
                  'can swipe back and look again at up to 10 profiles you passed.',
                  textAlign: TextAlign.center,
                  style: ZyraText.subtext(size: 13),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                backgroundColor: ZyraColors.journeyGold,
                foregroundColor: ZyraColors.espresso,
                textStyle: ZyraText.button(
                  size: 14,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
              onPressed: ZyraTapFeedback.onTap(context, onUpgrade),
              child: const Text('See Seeker One'),
            ),
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 52),
                backgroundColor: ZyraColors.ivoryTop,
                foregroundColor: ZyraColors.secondaryText,
                textStyle: ZyraText.button(size: 15),
              ),
              onPressed: ZyraTapFeedback.onTap(context, onDismiss),
              child: const Text('Not now'),
            ),
          ],
        ),
      ),
    ),
  );
}
