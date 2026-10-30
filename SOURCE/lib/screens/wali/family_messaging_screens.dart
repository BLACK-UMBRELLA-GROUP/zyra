import '../../widgets/zyra_tap_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import '../../dev/zyra_app_gold_preview.dart';
import '../../dev/zyra_guardian_circle_preview.dart';
import '../../dev/zyra_guardian_circle_topic_options.dart';
import '../../dev/zyra_circle_discussion_archive.dart';
import '../../dev/zyra_circle_discussion_picker_presentation.dart';
import '../../dev/zyra_circle_send_button_presentation.dart';

import '../../data/zyra_release_gates.dart';
import '../../dev/zyra_dev_surface_coordinator.dart';
import '../../models/journey_match.dart';
import '../../models/seeker_profile.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_family_messaging_service.dart';
import '../../services/zyra_journey_service.dart';
import '../../services/zyra_wali_journey_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_loading.dart';
import '../../widgets/zyra_pull_down_back_scope.dart';
import '../../widgets/zyra_guardian_preview_lifetime.dart';
import '../../widgets/zyra_message_receipt.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../journey/journey_flow_screen.dart';
import '../profile/seeker_profile_screen.dart';
import 'wali_journey_detail_screen.dart';

class ZyraGuardianCirclesInboxScreen extends StatefulWidget {
  final bool preview;

  const ZyraGuardianCirclesInboxScreen({super.key, this.preview = false});

  @override
  State<ZyraGuardianCirclesInboxScreen> createState() =>
      _ZyraGuardianCirclesInboxScreenState();
}

class _ZyraGuardianCirclesInboxScreenState
    extends State<ZyraGuardianCirclesInboxScreen> {
  bool _loading = true;
  bool _available = true;
  List<ZyraGuardianCircleSummary> _circles = const [];
  late final ZyraGuardianPreviewLifetime _authority;
  int _loadRequest = 0;

  @override
  void initState() {
    super.initState();
    _authority = ZyraGuardianPreviewLifetime(preview: widget.preview)
      ..addListener(_withdraw);
    _load();
  }

  @override
  void dispose() {
    _authority
      ..removeListener(_withdraw)
      ..dispose();
    super.dispose();
  }

  void _withdraw() {
    if (!mounted) return;
    _loadRequest++;
    setState(() {
      _loading = false;
      _available = false;
      _circles = const [];
    });
  }

  Future<void> _load() async {
    final request = ++_loadRequest;
    if (!_authority.isCurrent) {
      _withdraw();
      return;
    }
    if (_authority.canPreview) {
      setState(() {
        _loading = false;
        _available = true;
        _circles = [
          ZyraGuardianCircleSummary(
            threadId: 'dev-family-thread',
            seekerId: 'dev-seeker-aaliyah',
            seekerFirstName: 'Aaliyah',
            participantCount: 3,
            lastMessage: 'Let me know when you are ready to talk.',
            lastMessageAt: DateTime.now().subtract(const Duration(minutes: 8)),
            unreadCount: 1,
            canSend: true,
            muted: false,
            access: ZyraFamilyMessageAccess.ready,
          ),
        ];
      });
      return;
    }
    final result = await ZyraFamilyMessagingService.fetchCircles();
    if (!mounted || !_authority.isCurrent || request != _loadRequest) return;
    setState(() {
      _loading = false;
      _available = result.isAvailable;
      _circles = result.valueOr(const []);
    });
  }

  @override
  Widget build(BuildContext context) => ZyraGuardianPreviewRouteBoundary(
    authority: _authority,
    child: Scaffold(
      appBar: AppBar(title: const Text('Guardian Circles')),
      body: Container(
        decoration: ZyraAppGoldDecoration(
          gradient: ZyraColors.genderGradient(AppState.instance.gender),
        ),
        child: SafeArea(
          top: false,
          child: _loading
              ? const ZyraLoading(label: 'Loading messages…')
              : !_available
              ? ZyraUnknownErrorState(onRetry: _load)
              : _circles.isEmpty
              ? const ZyraEmptyState(
                  icon: Icons.forum_outlined,
                  title: 'No Guardian Circles yet',
                  message:
                      'A Seeker’s shared circle appears after you are linked as their Guardian.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
                  itemCount: _circles.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final circle = _circles[index];
                    return _GuardianCircleCard(
                      circle: circle,
                      onTap: () {
                        if (!_authority.isCurrent) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ZyraGuardianCircleScreen(
                              seekerId: circle.seekerId,
                              seekerFirstName: circle.seekerFirstName,
                              preview: widget.preview,
                              initialCircle: circle,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ),
    ),
  );
}

class ZyraGuardianCircleScreen extends StatefulWidget {
  final String seekerId;
  final String seekerFirstName;
  final bool viewerIsSeeker;
  final bool preview;
  final ZyraGuardianCircleSummary? initialCircle;
  final ValueChanged<ZyraFamilyMessageContext>? onOpenContext;
  final ZyraGuardianCirclePreviewData? previewData;
  // Detached developer presentation only. None of these values grants
  // preview, member access, history access or a send entitlement.
  final ValueListenable<ZyraCircleBubbleDesign>? previewBubbleDesign;
  final List<ZyraCircleDiscussionTopic> previewCurrentTopics;
  final List<ZyraCircleDiscussionTopic> previewPastTopics;
  final bool Function()? previewForeground;
  final ValueListenable<bool>? previewVisibility;
  // A pure, caller-owned read-only projection. A discussion label never
  // grants profile access; only an admitted current Seeker context may use it.
  final SeekerProfile? Function(ZyraFamilyMessageContext)?
  previewDiscussionProfileFor;
  // Explicit bounded past summary only. A topic/name alone is not an archive
  // or Guardian history grant; no profile or message lookup is inferred.
  final ZyraCircleDiscussionArchive? Function(ZyraCircleDiscussionTopic)?
  previewDiscussionArchiveFor;

  /// Denial-only scope supplied by a protected caller. This never enables
  /// preview or live access, and must allow this Circle's owned child sheets.
  final bool Function()? canAct;
  final VoidCallback? onBack;

  const ZyraGuardianCircleScreen({
    super.key,
    required this.seekerId,
    required this.seekerFirstName,
    this.viewerIsSeeker = false,
    this.preview = false,
    this.initialCircle,
    this.onOpenContext,
    this.previewData,
    this.previewBubbleDesign,
    this.previewCurrentTopics = const [],
    this.previewPastTopics = const [],
    this.previewForeground,
    this.previewVisibility,
    this.previewDiscussionProfileFor,
    this.previewDiscussionArchiveFor,
    this.canAct,
    this.onBack,
  });

  @override
  State<ZyraGuardianCircleScreen> createState() =>
      _ZyraGuardianCircleScreenState();
}

class _CircleDiscussionMarker {
  const _CircleDiscussionMarker({
    required this.sequence,
    required this.afterMessageCount,
    required this.topic,
  });

  final int sequence;
  final int afterMessageCount;
  final ZyraCircleDiscussionTopic topic;
}

class _ZyraGuardianCircleScreenState extends State<ZyraGuardianCircleScreen> {
  final _composer = TextEditingController();
  final _discussionLauncherKey = GlobalKey(
    debugLabel: 'circle-discussion-launcher',
  );
  bool _loading = true;
  bool _available = true;
  bool _sending = false;
  bool _confirmedCanSend = false;
  int _participantCount = 1;
  String? _threadId;
  ZyraFamilyMessageAccess _access = ZyraFamilyMessageAccess.unavailable;
  List<ZyraFamilyMessage> _messages = const [];
  ZyraFamilyMessageContext? _selectedContext;
  late final ZyraGuardianPreviewLifetime _authority;
  int _loadRequest = 0;
  late final ZyraGuardianCirclePreviewData? _previewData;
  late final bool Function()? _callerGuard;
  bool _callerRevoked = false;
  int _sendRequest = 0;
  late final ValueListenable<ZyraCircleBubbleDesign>? _bubbleDesign;
  late final List<ZyraCircleDiscussionTopic> _currentTopicExamples;
  late final List<ZyraCircleDiscussionTopic> _pastTopics;
  late final bool Function()? _previewForeground;
  late final ValueListenable<bool>? _previewVisibility;
  late final SeekerProfile? Function(ZyraFamilyMessageContext)?
  _discussionProfileResolver;
  late final ZyraCircleDiscussionArchive? Function(ZyraCircleDiscussionTopic)?
  _discussionArchiveResolver;
  final _topicMessageScroll = ScrollController();
  // Composer-owned pending metadata. Only a successful nonblank Send adds
  // its captured discussion card/tag to this local transcript.
  ZyraCircleDiscussionTopic? _discussionTopic;
  final _discussionMessageTags = <String, ZyraCircleDiscussionTopic>{};
  final _discussionMarkers = <_CircleDiscussionMarker>[];
  int _discussionMarkerSequence = 0;
  int _topicPickRequest = 0;
  int _messageReferenceEpoch = 0;

  static const _previewContexts = <ZyraFamilyMessageContext>[
    ZyraFamilyMessageContext(
      referenceId: 'dev-active-h',
      firstName: 'H.',
      kind: ZyraFamilyMessageContextKind.active,
    ),
    ZyraFamilyMessageContext(
      referenceId: 'dev-potential-m',
      firstName: 'M.',
      kind: ZyraFamilyMessageContextKind.potential,
    ),
    ZyraFamilyMessageContext(
      referenceId: 'dev-paused-r',
      firstName: 'R.',
      kind: ZyraFamilyMessageContextKind.paused,
    ),
    ZyraFamilyMessageContext(
      referenceId: 'dev-ended-s',
      firstName: 'S.',
      kind: ZyraFamilyMessageContextKind.ended,
    ),
  ];

  bool get _canPresentComposer =>
      mounted &&
      _authority.isCurrent &&
      _callerCurrent &&
      _available &&
      !_loading &&
      _confirmedCanSend &&
      _threadId != null &&
      _access == ZyraFamilyMessageAccess.ready;
  bool get _canSend => _canInteract && _canPresentComposer;

  bool get _topicOptionsEnabled =>
      _authority.canPreview &&
      _previewData != null &&
      _bubbleDesign != null &&
      _currentTopicExamples.map((topic) => topic.id).toSet().length ==
          _currentTopicExamples.length &&
      _currentTopicExamples.every(
        (topic) =>
            topic.kind == ZyraCircleTopicKind.current &&
            topic.id.startsWith('draft-circle-current-') &&
            topic.firstName.trim().isNotEmpty &&
            topic.firstName.length <= 80 &&
            topic.endedOn == null &&
            !_previewData.contexts.any(
              (active) => active.referenceId == topic.id,
            ) &&
            !_pastTopics.any((past) => past.id == topic.id),
      ) &&
      _pastTopics.map((topic) => topic.id).toSet().length ==
          _pastTopics.length &&
      _pastTopics.every(
        (topic) =>
            topic.kind == ZyraCircleTopicKind.past &&
            topic.id.startsWith('draft-circle-past-') &&
            topic.firstName.trim().isNotEmpty &&
            topic.firstName.length <= 80 &&
            topic.endedOn != null &&
            !_previewData.contexts.any(
              (active) => active.referenceId == topic.id,
            ),
      );
  ZyraCircleBubbleDesign get _discussionDesign =>
      _bubbleDesign?.value ?? ZyraCircleBubbleDesign.current;
  List<ZyraCircleDiscussionTopic> get _currentTopics {
    final contexts =
        _previewData?.contexts ?? const <ZyraFamilyMessageContext>[];
    if (contexts.isEmpty) {
      // Detached names make the empty protected picker testable. They are not
      // actual contexts, Journey state, profile capabilities or history grants.
      return _topicOptionsEnabled ? _currentTopicExamples : const [];
    }
    return [
      for (final item in contexts)
        ZyraCircleDiscussionTopic(
          id: item.referenceId,
          firstName: item.firstName,
          kind: ZyraCircleTopicKind.current,
        ),
    ];
  }

  bool _includesDiscussionTopic(ZyraCircleDiscussionTopic topic) =>
      topic == ZyraCircleDiscussionTopic.general ||
      [..._currentTopics, ..._pastTopics].any(
        (known) =>
            known.id == topic.id &&
            known.firstName == topic.firstName &&
            known.kind == topic.kind &&
            known.endedOn == topic.endedOn &&
            known.sharedSummaryLabel == topic.sharedSummaryLabel,
      );
  String get _currentSenderId => _authority.canPreview
      ? (_previewData?.senderId ?? 'dev-me')
      : (ZyraAuth.currentUser?.id ?? 'signed-out');

  bool get _callerCurrent {
    if (_callerRevoked) return false;
    bool allowed;
    try {
      allowed = _callerGuard?.call() ?? true;
    } catch (_) {
      allowed = false;
    }
    final data = _previewData;
    if (!allowed ||
        (widget.initialCircle != null &&
            widget.initialCircle!.seekerId != widget.seekerId) ||
        (data != null &&
            (!widget.preview ||
                !_authority.canPreview ||
                !data.validFor(
                  widget.seekerId,
                  viewerIsSeeker: widget.viewerIsSeeker,
                )))) {
      _denyCaller();
      return false;
    }
    return true;
  }

  bool get _canInteract {
    if (!mounted || !_authority.isCurrent || !_callerCurrent) return false;
    try {
      return (_previewForeground?.call() ?? true) &&
          (_previewVisibility?.value ?? true);
    } catch (_) {
      return false;
    }
  }

  bool get _canActOnCircleRoute =>
      _canInteract && (ModalRoute.of(context)?.isCurrent ?? false);

  void _denyCaller() {
    if (_callerRevoked) return;
    // Deny synchronously, including A→B→A, but withdraw owned routes only
    // after the current build. A getter may be reached during tree layout.
    _callerRevoked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _authority.revoke();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Widget _guardRoute(BuildContext context, Widget child) =>
      ZyraGuardianPreviewRouteBoundary(authority: _authority, child: child);

  @override
  void initState() {
    super.initState();
    _previewData = widget.previewData;
    _callerGuard = widget.canAct;
    _bubbleDesign = widget.previewBubbleDesign;
    _currentTopicExamples = List.unmodifiable(widget.previewCurrentTopics);
    _pastTopics = List.unmodifiable(widget.previewPastTopics);
    _previewForeground = widget.previewForeground;
    _previewVisibility = widget.previewVisibility;
    _discussionProfileResolver = widget.previewDiscussionProfileFor;
    _discussionArchiveResolver = widget.previewDiscussionArchiveFor;
    _authority = ZyraGuardianPreviewLifetime(preview: widget.preview)
      ..addListener(_withdraw);
    _bubbleDesign?.addListener(_presentationChanged);
    _previewVisibility?.addListener(_topicVisibilityChanged);
    _load();
  }

  @override
  void didUpdateWidget(covariant ZyraGuardianCircleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seekerId != widget.seekerId ||
        oldWidget.viewerIsSeeker != widget.viewerIsSeeker ||
        oldWidget.preview != widget.preview ||
        !identical(_callerGuard, widget.canAct) ||
        !identical(_previewData, widget.previewData) ||
        !identical(_bubbleDesign, widget.previewBubbleDesign) ||
        !identical(
          oldWidget.previewCurrentTopics,
          widget.previewCurrentTopics,
        ) ||
        !identical(oldWidget.previewPastTopics, widget.previewPastTopics) ||
        !identical(_previewForeground, widget.previewForeground) ||
        !identical(_previewVisibility, widget.previewVisibility) ||
        !identical(
          _discussionProfileResolver,
          widget.previewDiscussionProfileFor,
        ) ||
        !identical(
          _discussionArchiveResolver,
          widget.previewDiscussionArchiveFor,
        )) {
      _denyCaller();
    }
  }

  void _withdraw() {
    if (!mounted) return;
    _loadRequest++;
    _sendRequest++;
    _composer.clear();
    setState(() {
      _loading = false;
      _available = false;
      _sending = false;
      _confirmedCanSend = false;
      _participantCount = 0;
      _threadId = null;
      _access = ZyraFamilyMessageAccess.unavailable;
      _messages = const [];
      _selectedContext = null;
      _discussionTopic = null;
      _discussionMessageTags.clear();
      _discussionMarkers.clear();
      _topicPickRequest++;
      _messageReferenceEpoch++;
    });
  }

  @override
  void dispose() {
    _bubbleDesign?.removeListener(_presentationChanged);
    _previewVisibility?.removeListener(_topicVisibilityChanged);
    _topicMessageScroll.dispose();
    _composer.dispose();
    _authority
      ..removeListener(_withdraw)
      ..dispose();
    super.dispose();
  }

  void _presentationChanged() {
    if (!mounted || !_authority.isCurrent || !_callerCurrent) return;
    _topicPickRequest++;
    _messageReferenceEpoch++;
    // Repaint only. An existing selector lease is retired, while this Circle,
    // its transcript, selected reference and composer draft retain ownership.
    setState(() {});
  }

  void _topicVisibilityChanged() {
    if (!mounted || !_authority.isCurrent || !_callerCurrent) return;
    _messageReferenceEpoch++;
    setState(() {});
  }

  void _showLatestTopicMessage(int request, String threadId) {
    if (!_topicOptionsEnabled) return;
    final referenceEpoch = _messageReferenceEpoch;
    void reveal(int remainingLayouts) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_canActOnCircleRoute ||
            request != _sendRequest ||
            threadId != _threadId ||
            referenceEpoch != _messageReferenceEpoch ||
            !_topicMessageScroll.hasClients) {
          return;
        }
        final position = _topicMessageScroll.position;
        // User direction persists through a user fling, but remains idle for
        // our own animateTo. A newer Send may replace that older animation.
        if (position.userScrollDirection != ScrollDirection.idle ||
            (position.maxScrollExtent - position.pixels).abs() < .5) {
          return;
        }
        void afterScroll() {
          // A lazy transcript can revise its estimated end after laying out
          // the new card and message. Settle only this send, for at most four
          // layouts; deny a cover/new send and stop while the user scrolls.
          if (remainingLayouts > 0) reveal(remainingLayouts - 1);
        }

        if (MediaQuery.disableAnimationsOf(context) ||
            MediaQuery.accessibleNavigationOf(context)) {
          _topicMessageScroll.jumpTo(position.maxScrollExtent);
          afterScroll();
        } else {
          _topicMessageScroll
              .animateTo(
                position.maxScrollExtent,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
              )
              .then((_) => afterScroll());
        }
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    }

    reveal(3);
  }

  void _selectDiscussionTopic(ZyraCircleDiscussionTopic topic) {
    if (!_canActOnCircleRoute ||
        !_canSend ||
        _sending ||
        !_topicOptionsEnabled ||
        !_includesDiscussionTopic(topic)) {
      return;
    }
    setState(() {
      _discussionTopic = topic.isGeneral ? null : topic;
    });
  }

  VoidCallback? _removeDiscussionTopicAction() {
    final topic = _discussionTopic;
    if (!_topicOptionsEnabled || topic == null) return null;
    final threadId = _threadId;
    final loadRequest = _loadRequest;
    final sendRequest = _sendRequest;
    final topicPickRequest = _topicPickRequest;
    final referenceEpoch = _messageReferenceEpoch;
    return () {
      if (!_canActOnCircleRoute ||
          !_canSend ||
          _sending ||
          !_topicOptionsEnabled ||
          threadId != _threadId ||
          loadRequest != _loadRequest ||
          sendRequest != _sendRequest ||
          topicPickRequest != _topicPickRequest ||
          referenceEpoch != _messageReferenceEpoch ||
          !identical(topic, _discussionTopic) ||
          !_includesDiscussionTopic(topic)) {
        return;
      }
      setState(() => _discussionTopic = null);
    };
  }

  ({ZyraFamilyMessageContext context, SeekerProfile profile})?
  _discussionProfileFor(ZyraCircleDiscussionTopic topic) {
    // This may also be checked by the profile's own child route. Circle
    // route-current status is therefore checked separately before pushing it.
    if (!_canSend ||
        _sending ||
        !_topicOptionsEnabled ||
        !widget.viewerIsSeeker ||
        topic.id.startsWith('draft-circle-current-') ||
        topic.kind != ZyraCircleTopicKind.current ||
        !_includesDiscussionTopic(topic)) {
      return null;
    }
    final resolver = _discussionProfileResolver;
    if (resolver == null) return null;
    for (final candidate in _previewData!.contexts) {
      if (candidate.kind != ZyraFamilyMessageContextKind.active ||
          candidate.referenceId != topic.id ||
          candidate.firstName != topic.firstName) {
        continue;
      }
      try {
        final profile = resolver(candidate);
        if (profile == null ||
            profile.id != candidate.referenceId ||
            profile.firstName != candidate.firstName) {
          return null;
        }
        return (context: candidate, profile: profile);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  bool _discussionProfileCurrent(
    ZyraCircleDiscussionTopic topic,
    ({ZyraFamilyMessageContext context, SeekerProfile profile}) target,
  ) {
    final current = _discussionProfileFor(topic);
    return current != null &&
        identical(current.context, target.context) &&
        identical(current.profile, target.profile);
  }

  Future<void> _openDiscussionProfile(
    ZyraCircleDiscussionTopic topic,
    ({ZyraFamilyMessageContext context, SeekerProfile profile}) target,
  ) async {
    if (!_canActOnCircleRoute || !_discussionProfileCurrent(topic, target)) {
      return;
    }
    FocusScope.of(context).unfocus();
    BuildContext? profileContext;
    bool profileOwnerCurrent() {
      final child = profileContext;
      return child != null &&
          child.mounted &&
          _discussionProfileCurrent(topic, target);
    }

    void dismissProfile() {
      final child = profileContext;
      if (profileOwnerCurrent() &&
          child != null &&
          (ModalRoute.of(child)?.isCurrent ?? false)) {
        Navigator.of(child).pop();
      }
    }

    // Keep callbacks and the read-only child stable across route rebuilds.
    // The same Circle stays mounted; its lifetime revokes this owned route.
    final profile = SeekerProfileScreen(
      key: ValueKey(
        'circle_discussion_profile_route_${target.context.referenceId}',
      ),
      profile: target.profile,
      swipeDownToDismiss: true,
      // Route cover is an interaction denial, not lost profile ownership.
      // The renderer checks its own current route without revoking its owner.
      canAct: profileOwnerCurrent,
      onDismiss: dismissProfile,
    );
    if (!_canActOnCircleRoute || !_discussionProfileCurrent(topic, target)) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (childContext) {
          profileContext = childContext;
          return _guardRoute(childContext, profile);
        },
      ),
    );
  }

  ZyraCircleDiscussionArchive? _discussionArchiveFor(
    ZyraCircleDiscussionTopic topic,
  ) {
    // Owned controls can cover this chat without removing archive ownership.
    // Foreground/current-route interaction is checked separately before push.
    if (!_canPresentComposer ||
        _sending ||
        !_topicOptionsEnabled ||
        !topic.isPast ||
        !_includesDiscussionTopic(topic)) {
      return null;
    }
    try {
      final archive = _discussionArchiveResolver?.call(topic);
      if (archive == null ||
          archive.topicId != topic.id ||
          archive.firstName != topic.firstName ||
          archive.sharedSummaryLabel != topic.sharedSummaryLabel ||
          archive.endedOn != topic.endedOn ||
          archive.startedOn.isAfter(archive.endedOn)) {
        return null;
      }
      return archive;
    } catch (_) {
      return null;
    }
  }

  Future<void> _openDiscussionArchive(
    ZyraCircleDiscussionTopic topic,
    ZyraCircleDiscussionArchive archive,
  ) async {
    bool targetCurrent() => identical(_discussionArchiveFor(topic), archive);
    if (!_canActOnCircleRoute || !targetCurrent()) return;
    FocusScope.of(context).unfocus();
    BuildContext? archiveContext;
    bool ownerCurrent() =>
        archiveContext != null && archiveContext!.mounted && targetCurrent();
    void close() {
      if (_canInteract &&
          ownerCurrent() &&
          (ModalRoute.of(archiveContext!)?.isCurrent ?? false)) {
        Navigator.of(archiveContext!).pop();
      }
    }

    final child = ZyraCircleDiscussionArchiveView(
      key: ValueKey('circle_discussion_archive_${topic.id}'),
      archive: archive,
      canAct: ownerCurrent,
      onClose: close,
    );
    if (!_canActOnCircleRoute || !targetCurrent()) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (childContext) {
          archiveContext = childContext;
          return _guardRoute(childContext, child);
        },
      ),
    );
  }

  Future<void> _chooseDiscussionTopic() async {
    if (!_canActOnCircleRoute ||
        !_canSend ||
        _sending ||
        !_topicOptionsEnabled) {
      return;
    }
    await _choosePresentedDiscussionTopic(_discussionDesign);
  }

  Rect? _discussionLauncherBounds() {
    final launcher = _discussionLauncherKey.currentContext?.findRenderObject();
    final overlay = Navigator.of(context).overlay?.context.findRenderObject();
    if (launcher is! RenderBox ||
        overlay is! RenderBox ||
        !launcher.attached ||
        !overlay.attached ||
        !launcher.hasSize ||
        launcher.size.isEmpty) {
      return null;
    }
    final origin = launcher.localToGlobal(Offset.zero, ancestor: overlay);
    if (!origin.dx.isFinite || !origin.dy.isFinite) return null;
    return origin & launcher.size;
  }

  Future<void> _choosePresentedDiscussionTopic(
    ZyraCircleBubbleDesign design,
  ) async {
    final request = ++_topicPickRequest;
    final sendRequest = _sendRequest;
    final loadRequest = _loadRequest;
    final threadId = _threadId;
    final referenceEpoch = _messageReferenceEpoch;
    final selected = _discussionTopic ?? ZyraCircleDiscussionTopic.general;
    final currentTopics = List<ZyraCircleDiscussionTopic>.unmodifiable(
      _currentTopics,
    );
    final pastTopics = List<ZyraCircleDiscussionTopic>.unmodifiable(
      _pastTopics,
    );
    final launcherBounds = _discussionLauncherBounds();
    bool requestCurrent() =>
        _canInteract &&
        _canSend &&
        !_sending &&
        _topicOptionsEnabled &&
        request == _topicPickRequest &&
        design == _discussionDesign &&
        sendRequest == _sendRequest &&
        loadRequest == _loadRequest &&
        threadId == _threadId &&
        referenceEpoch == _messageReferenceEpoch;
    FocusScope.of(context).unfocus();
    Widget picker(BuildContext pickerContext) {
      bool routeCurrent() =>
          pickerContext.mounted &&
          (ModalRoute.of(pickerContext)?.isCurrent ?? false);
      bool canSelect() => routeCurrent() && requestCurrent();
      void close() {
        // Cancellation belongs to this exact route, even if its selection
        // epoch was retired. It cannot pop a covering or replacement route.
        if (routeCurrent() && _canInteract) Navigator.of(pickerContext).pop();
      }

      return _guardRoute(
        pickerContext,
        ZyraCircleDiscussionPickerPresentation(
          design: design,
          currentTopics: currentTopics,
          pastTopics: pastTopics,
          selected: selected,
          canSelect: canSelect,
          onSelected: (topic) {
            if (canSelect() && _includesDiscussionTopic(topic)) {
              Navigator.of(pickerContext).pop(topic);
            }
          },
          onClose: close,
          launcherBounds: launcherBounds,
        ),
      );
    }

    final route = RawDialogRoute<ZyraCircleDiscussionTopic>(
      pageBuilder: (pickerContext, animation, secondaryAnimation) =>
          picker(pickerContext),
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: .36),
      transitionDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
    );
    if (!_canActOnCircleRoute || !requestCurrent()) return;
    final chosen = await Navigator.of(context).push(route);
    if (chosen != null && _canActOnCircleRoute && requestCurrent()) {
      _selectDiscussionTopic(chosen);
    }
  }

  // Session-local annotation only. Existing server contexts, message bodies,
  // other senders and the composer topic are never rewritten by this action.
  bool _messageReferenceCurrent(ZyraFamilyMessage message) =>
      _canSend &&
      !_sending &&
      _topicOptionsEnabled &&
      !message.lifecycle &&
      message.context == null &&
      message.senderId == _currentSenderId &&
      _messages.any((current) => identical(current, message));

  VoidCallback? _messageReferenceAction(ZyraFamilyMessage message) {
    if (!_messageReferenceCurrent(message)) return null;
    final epoch = _messageReferenceEpoch;
    final sendRequest = _sendRequest;
    final loadRequest = _loadRequest;
    final threadId = _threadId;
    return () {
      if (epoch == _messageReferenceEpoch &&
          sendRequest == _sendRequest &&
          loadRequest == _loadRequest &&
          threadId == _threadId) {
        _chooseMessageJourneyReference(message);
      }
    };
  }

  Future<void> _chooseMessageJourneyReference(ZyraFamilyMessage message) async {
    if (!_canActOnCircleRoute || !_messageReferenceCurrent(message)) return;
    final request = ++_topicPickRequest;
    final referenceEpoch = _messageReferenceEpoch;
    final sendRequest = _sendRequest;
    final loadRequest = _loadRequest;
    final threadId = _threadId;
    final design = _discussionDesign;
    bool originalMessageCurrent() =>
        request == _topicPickRequest &&
        referenceEpoch == _messageReferenceEpoch &&
        sendRequest == _sendRequest &&
        loadRequest == _loadRequest &&
        threadId == _threadId &&
        design == _discussionDesign &&
        _messageReferenceCurrent(message);
    FocusScope.of(context).unfocus();
    final chosen = await showModalBottomSheet<ZyraCircleDiscussionTopic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        bool sheetCurrent() =>
            sheetContext.mounted &&
            originalMessageCurrent() &&
            (ModalRoute.of(sheetContext)?.isCurrent ?? false);
        return _guardRoute(
          sheetContext,
          ZyraCircleTopicPicker(
            currentTopics: _currentTopics,
            pastTopics: _pastTopics,
            selected:
                _discussionMessageTags[message.id] ??
                ZyraCircleDiscussionTopic.general,
            title: 'Link a Journey',
            canSelect: sheetCurrent,
            onSelected: (topic) {
              if (sheetCurrent() && _includesDiscussionTopic(topic)) {
                Navigator.of(sheetContext).pop(topic);
              }
            },
          ),
        );
      },
    );
    if (chosen == null ||
        !_canActOnCircleRoute ||
        !originalMessageCurrent() ||
        !_includesDiscussionTopic(chosen)) {
      return;
    }
    final previous = _discussionMessageTags[message.id];
    if ((chosen.isGeneral && previous == null) ||
        (previous?.id == chosen.id &&
            previous?.firstName == chosen.firstName &&
            previous?.kind == chosen.kind &&
            previous?.endedOn == chosen.endedOn &&
            previous?.sharedSummaryLabel == chosen.sharedSummaryLabel)) {
      return;
    }
    setState(() {
      if (chosen.isGeneral) {
        _discussionMessageTags.remove(message.id);
      } else {
        _discussionMessageTags[message.id] = chosen;
      }
    });
  }

  Future<void> _load() async {
    final request = ++_loadRequest;
    if (!_canInteract) {
      _withdraw();
      return;
    }
    if (_authority.canPreview) {
      final data = _previewData;
      if (data != null) {
        setState(() {
          _loading = false;
          _available = true;
          _threadId = 'preview-circle-${data.seekerId}';
          _participantCount = data.participants.length;
          _confirmedCanSend = data.canSend && _participantCount > 1;
          _access = _participantCount <= 1
              ? ZyraFamilyMessageAccess.linkInactive
              : _confirmedCanSend
              ? ZyraFamilyMessageAccess.ready
              : ZyraFamilyMessageAccess.membershipRequired;
          _messages = data.messages;
        });
        return;
      }
      setState(() {
        _loading = false;
        _available = true;
        _threadId = widget.initialCircle?.threadId ?? 'dev-family-thread';
        _participantCount = widget.initialCircle?.participantCount ?? 3;
        _access = widget.initialCircle?.access ?? ZyraFamilyMessageAccess.ready;
        _confirmedCanSend = widget.initialCircle?.canSend ?? true;
        _messages = [
          ZyraFamilyMessage(
            id: 'dev-family-1',
            senderId: widget.seekerId,
            senderFirstName: widget.seekerFirstName,
            senderRoleLabel: 'Seeker',
            body: 'Assalaamu alaikum. I wanted to discuss this together.',
            createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
            context: _previewContexts.first,
          ),
          ZyraFamilyMessage(
            id: 'dev-family-2',
            senderId: 'dev-circle-guardian',
            senderFirstName: 'Abdul',
            senderRelationship: 'father',
            senderRoleLabel: 'Main Guardian',
            body: 'Wa alaikum assalaam. We can all discuss it here.',
            createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
            unreadForMe: true,
          ),
          ZyraFamilyMessage(
            id: 'dev-family-3',
            senderId: 'dev-me',
            senderFirstName: 'You',
            senderRoleLabel: widget.viewerIsSeeker ? 'Seeker' : 'Main Guardian',
            body: 'JazakAllah khair. Let’s discuss it together.',
            createdAt: DateTime.now().subtract(const Duration(minutes: 6)),
            readBy: [
              ZyraFamilyMessageReader(
                userId: widget.viewerIsSeeker
                    ? 'dev-circle-main-guardian'
                    : widget.seekerId,
                firstName: widget.viewerIsSeeker
                    ? 'Abdul'
                    : widget.seekerFirstName,
                roleLabel: widget.viewerIsSeeker ? 'Main Guardian' : 'Seeker',
                readAt: DateTime.now().subtract(const Duration(minutes: 4)),
              ),
              ZyraFamilyMessageReader(
                userId: 'dev-circle-additional-guardian',
                firstName: 'Hassan',
                roleLabel: 'Additional Guardian',
                readAt: DateTime.now().subtract(const Duration(minutes: 2)),
              ),
            ],
          ),
        ];
      });
      return;
    }
    if (!ZyraReleaseGates.familyMessagingEnabled) {
      _withdraw();
      return;
    }
    setState(() {
      _loading = true;
      _available = false;
      _confirmedCanSend = false;
    });
    final accessResult = await ZyraFamilyMessagingService.openCircle(
      widget.seekerId,
    );
    if (!_canInteract || request != _loadRequest) return;
    final access = accessResult.valueOrNull;
    if (!accessResult.isAvailable ||
        access == null ||
        access.seekerId != widget.seekerId) {
      _withdraw();
      return;
    }
    _threadId = access.threadId;
    _access = access.access;
    _confirmedCanSend = access.canSend;
    _participantCount = access.participantCount;
    final id = access.threadId;
    if (id == null) {
      setState(() {
        _loading = false;
        _available = true;
        _messages = const [];
        _selectedContext = null;
        _confirmedCanSend = false;
      });
      return;
    }
    final messages = await ZyraFamilyMessagingService.fetchMessages(id);
    if (!_canInteract || request != _loadRequest) return;
    if (!messages.isAvailable) {
      _withdraw();
      return;
    }
    setState(() {
      _loading = false;
      _available = messages.isAvailable;
      _messages = messages.valueOr(const []);
    });
    if (_canActOnCircleRoute && request == _loadRequest) {
      await ZyraFamilyMessagingService.markRead(id);
    }
  }

  Future<void> _send() async {
    if (!_canActOnCircleRoute) return;
    final draft = _composer.text;
    final text = draft.trim();
    final threadId = _threadId;
    if (!_canSend ||
        _sending ||
        text.isEmpty ||
        text.length > 2000 ||
        threadId == null) {
      return;
    }
    final comparison = _topicOptionsEnabled;
    final discussionTopic = comparison ? _discussionTopic : null;
    if (discussionTopic != null && !_includesDiscussionTopic(discussionTopic)) {
      return;
    }
    final request = ++_sendRequest;
    final loadRequest = _loadRequest;
    final senderId = _currentSenderId;
    final topicPickRequest = _topicPickRequest;
    final referenceEpoch = _messageReferenceEpoch;
    final selectedContext = comparison ? null : _selectedContext;
    setState(() => _sending = true);
    if (_authority.canPreview) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!_canActOnCircleRoute ||
          !_authority.canPreview ||
          request != _sendRequest ||
          loadRequest != _loadRequest ||
          threadId != _threadId ||
          senderId != _currentSenderId ||
          comparison != _topicOptionsEnabled ||
          (comparison &&
              (topicPickRequest != _topicPickRequest ||
                  referenceEpoch != _messageReferenceEpoch ||
                  !identical(discussionTopic, _discussionTopic))) ||
          (discussionTopic != null &&
              !_includesDiscussionTopic(discussionTopic))) {
        _finishSending(request);
        return;
      }
      setState(() {
        var messageNumber = _messages.length + 1;
        while (_messages.any(
          (message) => message.id == 'dev-family-$messageNumber',
        )) {
          messageNumber++;
        }
        final messageId = 'dev-family-$messageNumber';
        if (discussionTopic != null) {
          _discussionMarkers.add(
            _CircleDiscussionMarker(
              sequence: ++_discussionMarkerSequence,
              afterMessageCount: _messages.length,
              topic: discussionTopic,
            ),
          );
          _discussionMessageTags[messageId] = discussionTopic;
        }
        _messages = [
          ..._messages,
          ZyraFamilyMessage(
            id: messageId,
            senderId: senderId,
            senderFirstName: 'You',
            senderRoleLabel: _previewData?.participants
                .where((person) => person.isCurrentUser)
                .firstOrNull
                ?.roleLabel,
            body: text,
            createdAt: DateTime.now(),
            context: selectedContext,
          ),
        ];
        _sending = false;
        _selectedContext = null;
        if (identical(_discussionTopic, discussionTopic)) {
          _discussionTopic = null;
        }
        if (_composer.text == draft) _composer.clear();
      });
      _showLatestTopicMessage(request, threadId);
      return;
    }
    final sent = await ZyraFamilyMessagingService.send(threadId, text);
    _finishSending(request);
    if (!_canActOnCircleRoute ||
        request != _sendRequest ||
        loadRequest != _loadRequest ||
        threadId != _threadId) {
      return;
    }
    if (sent) {
      if (_composer.text == draft) _composer.clear();
      await _load();
    } else {
      _notice('That message could not be sent. Please try again.');
    }
  }

  void _finishSending(int request) {
    if (mounted && request == _sendRequest && _sending) {
      setState(() => _sending = false);
    }
  }

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _chooseContext() async {
    if (!_canActOnCircleRoute ||
        !_authority.canPreview ||
        _topicOptionsEnabled) {
      return;
    }
    final contexts = _previewData?.contexts ?? _previewContexts;
    if (contexts.isEmpty ||
        (_previewData != null && widget.onOpenContext == null)) {
      return;
    }
    FocusScope.of(context).unfocus();
    final chosen = await showModalBottomSheet<ZyraFamilyMessageContext>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _guardRoute(context, _MessageContextPicker(contexts: contexts)),
    );
    if (chosen != null &&
        _canActOnCircleRoute &&
        _authority.canPreview &&
        (_previewData?.includesContext(chosen) ?? true)) {
      setState(() => _selectedContext = chosen);
    }
  }

  Future<void> _openMessageContext(
    ZyraFamilyMessageContext messageContext,
  ) async {
    if (!_canActOnCircleRoute) return;
    FocusScope.of(context).unfocus();
    final callback = widget.onOpenContext;
    final supplied = _previewData;
    if (supplied != null) {
      if (supplied.includesContext(messageContext)) {
        callback?.call(messageContext);
      }
      return;
    }
    if (callback != null) {
      callback(messageContext);
      return;
    }

    if (messageContext.kind == ZyraFamilyMessageContextKind.active) {
      if (widget.viewerIsSeeker) {
        final journey = await _resolveSeekerJourney(messageContext);
        if (!mounted || !_canInteract) return;
        if (journey != null) {
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (context) => _guardRoute(
                context,
                JourneyFlowScreen(
                  matchId: journey.matchId,
                  profile: journey.profile,
                ),
              ),
            ),
          );
          return;
        }
        if (_authority.canPreview) {
          // A fixture has no server Journey to open. Move to the real Journey
          // owner instead of presenting a broken Journey route.
          ZyraDevSurfaceCoordinator.instance.openSeekerConnectionsSection(0);
          Navigator.of(
            context,
            rootNavigator: true,
          ).popUntil((route) => route.isFirst);
          return;
        }
      } else {
        final journey = await _resolveGuardianJourney(messageContext);
        if (!mounted || !_canInteract) return;
        if (journey != null) {
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (context) => _guardRoute(
                context,
                WaliJourneyDetailScreen(journey: journey),
              ),
            ),
          );
          return;
        }
      }
      _notice('That Active Journey is not available right now.');
      return;
    }

    final journey = await _resolveSeekerJourney(messageContext);
    if (!mounted || !_canInteract) return;
    final profile =
        journey?.profile ??
        (_authority.canPreview ? _previewProfile(messageContext) : null);
    if (profile == null) {
      _notice('That Active Journey is not available right now.');
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => _guardRoute(
          context,
          SeekerProfileScreen(
            profile: profile,
            stateLabel: messageContext.stateLabel,
            swipeDownToDismiss: true,
          ),
        ),
      ),
    );
  }

  Future<JourneyMatch?> _resolveSeekerJourney(
    ZyraFamilyMessageContext messageContext,
  ) async {
    if (!_canInteract) return null;
    final cached = <JourneyMatch>[
      ...AppState.instance.activeJourneys,
      ...AppState.instance.potentialJourneys,
    ];
    final cachedMatch = _matchingJourney(cached, messageContext.referenceId);
    if (cachedMatch != null) return cachedMatch;
    if (_authority.canPreview) return null;
    final journeys = await ZyraJourneyService.fetchJourneyMatches(
      statuses: const ['potential', 'active', 'ended'],
    );
    if (!_canInteract) return null;
    return _matchingJourney(journeys ?? const [], messageContext.referenceId);
  }

  Future<WaliJourneyView?> _resolveGuardianJourney(
    ZyraFamilyMessageContext messageContext,
  ) async {
    if (!_canInteract) return null;
    if (!_authority.canPreview) {
      final journeys = await ZyraWaliJourneyService.fetchLinkedJourneys();
      if (!_canInteract) return null;
      if (journeys != null) {
        for (final journey in journeys) {
          if (journey.matchId == messageContext.referenceId) return journey;
        }
      }
      return null;
    }
    final profile = _previewProfile(messageContext);
    return WaliJourneyView(
      matchId: messageContext.referenceId,
      linkedSeekerId: widget.seekerId,
      linkedSeekerName: widget.seekerFirstName,
      partner: profile,
      counterpartGuardianName: null,
      counterpartGuardianSurname: null,
      status: 'active',
      journeyStage: 'salam_exchange',
      isMock: true,
    );
  }

  JourneyMatch? _matchingJourney(
    List<JourneyMatch> journeys,
    String referenceId,
  ) {
    for (final journey in journeys) {
      if (journey.matchId == referenceId || journey.profile.id == referenceId) {
        return journey;
      }
    }
    return null;
  }

  SeekerProfile _previewProfile(ZyraFamilyMessageContext messageContext) {
    final index = ZyraFamilyMessageContextKind.values.indexOf(
      messageContext.kind,
    );
    final seed = mockProfiles[index % mockProfiles.length];
    return SeekerProfile(
      id: messageContext.referenceId,
      firstName: messageContext.firstName,
      age: seed.age,
      city: seed.city,
      photos: seed.photos,
      gender: seed.gender,
    );
  }

  void _showMembers() {
    if (!_canActOnCircleRoute) return;
    final threadId = _threadId;
    if (threadId == null) {
      _notice('Circle members are not available right now.');
      return;
    }
    final previewParticipants = _authority.canPreview
        ? (_previewData?.participants ??
              <ZyraFamilyCircleParticipant>[
                ZyraFamilyCircleParticipant(
                  userId: widget.seekerId,
                  firstName: widget.seekerFirstName,
                  memberRole: 'seeker',
                  isMainGuardian: false,
                  isCurrentUser: widget.viewerIsSeeker,
                ),
                ZyraFamilyCircleParticipant(
                  userId: 'dev-circle-main-guardian',
                  firstName: 'Abdul',
                  memberRole: 'guardian',
                  isMainGuardian: true,
                  isCurrentUser: !widget.viewerIsSeeker,
                ),
                const ZyraFamilyCircleParticipant(
                  userId: 'dev-circle-additional-guardian',
                  firstName: 'Hassan',
                  memberRole: 'guardian',
                  isMainGuardian: false,
                  isCurrentUser: false,
                ),
              ])
        : null;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _guardRoute(
        context,
        _CircleMembersSheet(
          threadId: threadId,
          expectedCount: _participantCount,
          previewParticipants: previewParticipants,
          canInteract: () => _canInteract,
        ),
      ),
    );
  }

  Future<void> _report(ZyraFamilyMessage message) async {
    if (!_canActOnCircleRoute) return;
    if (_authority.canPreview) {
      _notice('Preview only — no report was sent.');
      return;
    }
    final threadId = _threadId;
    if (threadId == null) return;
    final request = _loadRequest;
    final sent = await ZyraFamilyMessagingService.report(
      threadId: threadId,
      messageId: message.id,
      reason: 'other',
    );
    if (_canActOnCircleRoute &&
        request == _loadRequest &&
        threadId == _threadId) {
      _notice(sent ? 'Report sent.' : 'Report could not be sent.');
    }
  }

  void _closeCircle() {
    if (!_canActOnCircleRoute) return;
    final back = widget.onBack;
    if (back != null) {
      back();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Widget _withBackReturn(BuildContext context, Widget child) {
    // The request shell already owns the return for its embedded Circle.
    // Direct member/legacy routes need the same gesture and accessible
    // return action, never a second competing edge recognizer.
    if (context.findAncestorWidgetOfExactType<ZyraPullDownBackScope>() !=
        null) {
      return child;
    }
    return ZyraPullDownBackScope(
      key: const ValueKey('circle_pull_down_back_scope'),
      routeIdentity: (this, widget.onBack),
      enabled: _canActOnCircleRoute,
      inlineBackHeader: true,
      onBack: _closeCircle,
      child: child,
    );
  }

  bool get _showDiscussControl => _canPresentComposer && _topicOptionsEnabled;

  Widget _discussControl() {
    final design = _discussionDesign;
    return KeyedSubtree(
      key: _discussionLauncherKey,
      child: ZyraCircleDiscussLauncher(
        key: const ValueKey('circle_discuss_floatingButton'),
        topic: _discussionTopic ?? ZyraCircleDiscussionTopic.general,
        onChoose: _sending
            ? null
            : () {
                if (_discussionDesign == design) _chooseDiscussionTopic();
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => !_callerCurrent
      ? const SizedBox.shrink()
      : _withBackReturn(
          context,
          ZyraGuardianPreviewRouteBoundary(
            authority: _authority,
            child: Scaffold(
              resizeToAvoidBottomInset: true,
              body: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: ZyraTapFeedback.onTap(
                  context,
                  () => FocusScope.of(context).unfocus(),
                ),
                child: Container(
                  decoration: ZyraAppGoldDecoration(
                    gradient: ZyraColors.genderGradient(
                      AppState.instance.gender,
                    ),
                  ),
                  child: SafeArea(
                    child: _CircleComposerViewport(
                      builder: (dockDiscussion) => Column(
                        children: [
                          _CircleHeader(
                            participantCount: _participantCount,
                            onShowMembers: _showMembers,
                            compactPending:
                                dockDiscussion &&
                                _topicOptionsEnabled &&
                                _discussionTopic != null,
                          ),
                          if (!_loading && _available && !_canPresentComposer)
                            _ReadOnlyBanner(access: _access),
                          Expanded(
                            key: const ValueKey('circle_transcript_viewport'),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _loading
                                    ? const ZyraLoading(
                                        label: 'Opening conversation…',
                                      )
                                    : !_available
                                    ? ZyraUnknownErrorState(onRetry: _load)
                                    : _messages.isEmpty &&
                                          _discussionMarkers.isEmpty
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(28),
                                          child: ZyraEmptyState(
                                            icon: Icons.forum_outlined,
                                            title: 'Start the Guardian Circle',
                                            message:
                                                'A private place for the Seeker and their linked Guardians to talk together.',
                                          ),
                                        ),
                                      )
                                    : _messageList(
                                        floatingDiscussion:
                                            _showDiscussControl &&
                                            !dockDiscussion,
                                      ),
                                if (_showDiscussControl && !dockDiscussion)
                                  Align(
                                    alignment: Alignment.bottomLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        18,
                                        4,
                                        18,
                                        8,
                                      ),
                                      child: _discussControl(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (_canPresentComposer)
                            ZyraFamilyMessageComposer(
                              key: const ValueKey('circle_composer_owner'),
                              controller: _composer,
                              busy: _sending,
                              compactDiscussion: true,
                              discussionAction:
                                  dockDiscussion && _showDiscussControl
                                  ? _discussControl()
                                  : null,
                              selectedContext: _topicOptionsEnabled
                                  ? null
                                  : _selectedContext,
                              pendingDiscussionTopic: _topicOptionsEnabled
                                  ? _discussionTopic
                                  : null,
                              onRemoveDiscussionTopic:
                                  _removeDiscussionTopicAction(),
                              contextEnabled:
                                  !_topicOptionsEnabled &&
                                  _authority.canPreview &&
                                  (_previewData == null ||
                                      (_previewData.contexts.isNotEmpty &&
                                          widget.onOpenContext != null)),
                              onChooseContext: _chooseContext,
                              onRemoveContext: () {
                                if (_canActOnCircleRoute &&
                                    !_topicOptionsEnabled) {
                                  setState(() => _selectedContext = null);
                                }
                              },
                              onOpenContext: _topicOptionsEnabled
                                  ? null
                                  : switch (_selectedContext) {
                                      final selected? => () {
                                        if (!_topicOptionsEnabled &&
                                            identical(
                                              _selectedContext,
                                              selected,
                                            )) {
                                          _openMessageContext(selected);
                                        }
                                      },
                                      null => null,
                                    },
                              onSend: _send,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

  Widget _messageList({required bool floatingDiscussion}) {
    final latestMine = _messages.lastIndexWhere(
      (message) => message.senderId == _currentSenderId && !message.lifecycle,
    );
    final firstUnread = _messages.indexWhere(
      (message) => message.unreadForMe && !message.lifecycle,
    );
    final children = <Widget>[const _TodayDivider()];
    void appendDiscussionMarkers(int afterMessageCount) {
      for (final marker in _discussionMarkers) {
        if (marker.afterMessageCount.clamp(0, _messages.length) !=
            afterMessageCount) {
          continue;
        }
        final target = _canActOnCircleRoute
            ? _discussionProfileFor(marker.topic)
            : null;
        final archive = _canActOnCircleRoute
            ? _discussionArchiveFor(marker.topic)
            : null;
        children.add(
          ZyraCircleDiscussionBubble(
            key: ValueKey('circle_discussion_marker_${marker.sequence}'),
            topic: marker.topic,
            onViewProfile: target == null
                ? null
                : () => _openDiscussionProfile(marker.topic, target),
            onViewJourney: archive == null
                ? null
                : () => _openDiscussionArchive(marker.topic, archive),
          ),
        );
      }
    }

    appendDiscussionMarkers(0);
    for (var index = 0; index < _messages.length; index++) {
      final message = _messages[index];
      if (index == firstUnread) {
        children.add(const ZyraUnreadMessagesDivider());
      }
      children.add(
        _FamilyMessageBubble(
          message: message,
          mine: message.senderId == _currentSenderId,
          showReceipt: index == latestMine,
          recipientCount: (_participantCount - 1).clamp(0, 99),
          canInteract: () => _canInteract,
          canOpen: () => _canActOnCircleRoute,
          sheetWrapper: _guardRoute,
          discussionTopic: _discussionMessageTags[message.id],
          onChooseJourneyReference: _messageReferenceAction(message),
          onOpenContext: message.context == null
              ? null
              : () => _openMessageContext(message.context!),
          onReport:
              message.senderId != null && message.senderId != _currentSenderId
              ? () => _report(message)
              : null,
        ),
      );
      appendDiscussionMarkers(index + 1);
    }
    return ListView(
      controller: _topicOptionsEnabled ? _topicMessageScroll : null,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      // Keep the whole viewport available behind the floating launcher. Only
      // trailing content needs clearance so the last message and receipt can
      // scroll above it; no full-width strip belongs to the launcher.
      padding: EdgeInsets.fromLTRB(20, 12, 20, floatingDiscussion ? 82 : 18),
      children: children,
    );
  }
}

class _GuardianCircleCard extends StatelessWidget {
  final ZyraGuardianCircleSummary circle;
  final VoidCallback onTap;

  const _GuardianCircleCard({required this.circle, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: ZyraColors.surfaceFill,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: ZyraTapFeedback.onTap(context, onTap),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ZyraColors.surfaceBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ZyraColors.surfaceFill,
                border: Border.all(color: ZyraColors.surfaceEmphasisBorder),
              ),
              child: Text(circle.seekerFirstName[0].toUpperCase()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${circle.seekerFirstName}’s Guardian Circle',
                    style: ZyraText.body(size: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    circle.lastMessage ??
                        '${circle.participantCount} members · No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ZyraText.subtext(size: 12),
                  ),
                ],
              ),
            ),
            if (circle.unreadCount > 0)
              Container(
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: ZyraColors.actionFill,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  '${circle.unreadCount}',
                  style: ZyraText.body(size: 11, color: Colors.black),
                ),
              )
            else
              Icon(Icons.chevron_right_rounded, color: ZyraColors.ink(0.5)),
          ],
        ),
      ),
    ),
  );
}

class _CircleHeader extends StatelessWidget {
  const _CircleHeader({
    required this.participantCount,
    required this.onShowMembers,
    this.compactPending = false,
  });

  final int participantCount;
  final VoidCallback onShowMembers;
  final bool compactPending;

  @override
  Widget build(BuildContext context) {
    final backSize = ZyraInlineBackButton.preferredSizeOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        compactPending ? 0 : 5,
        20,
        compactPending ? 2 : 9,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          if (backSize != null) ...[
            SizedBox(
              width: backSize.width,
              height: backSize.height,
              child: const ZyraInlineBackButton(),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Semantics(
              button: true,
              label:
                  'Guardian Circle, $participantCount ${participantCount == 1 ? 'member' : 'members'}, view members',
              onTap: ZyraTapFeedback.onTap(context, onShowMembers),
              excludeSemantics: true,
              child: InkWell(
                key: const ValueKey('circle_header_members'),
                onTap: ZyraTapFeedback.onTap(context, onShowMembers),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: compactPending ? 2 : 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (compactPending)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          primary: false,
                          child: Text(
                            'Guardian Circle',
                            softWrap: false,
                            style: ZyraText.heading(size: 20),
                          ),
                        )
                      else
                        Text(
                          'Guardian Circle',
                          style: ZyraText.heading(size: 20),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        '$participantCount ${participantCount == 1 ? 'member' : 'members'}',
                        style: ZyraText.subtext(size: 10.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleMembersSheet extends StatefulWidget {
  final String threadId;
  final int expectedCount;
  final List<ZyraFamilyCircleParticipant>? previewParticipants;
  final bool Function()? canInteract;

  const _CircleMembersSheet({
    required this.threadId,
    required this.expectedCount,
    this.previewParticipants,
    this.canInteract,
  });

  @override
  State<_CircleMembersSheet> createState() => _CircleMembersSheetState();
}

class _CircleMembersSheetState extends State<_CircleMembersSheet> {
  bool _loading = true;
  bool _available = true;
  List<ZyraFamilyCircleParticipant> _participants = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.canInteract?.call() == false) return;
    final preview = widget.previewParticipants;
    if (preview != null) {
      setState(() {
        _loading = false;
        _available = true;
        _participants = preview;
      });
      return;
    }
    setState(() => _loading = true);
    final result = await ZyraFamilyMessagingService.fetchParticipants(
      widget.threadId,
    );
    if (!mounted || widget.canInteract?.call() == false) return;
    setState(() {
      _loading = false;
      _available = result.isAvailable;
      _participants = result.valueOr(const []);
    });
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.70,
      ),
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      decoration: BoxDecoration(
        color: ZyraColors.waliSheetBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ZyraColors.surfaceBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: ZyraColors.ink(0.22),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Circle members', style: ZyraText.heading(size: 21)),
          const SizedBox(height: 5),
          Text(
            '${widget.expectedCount} ${widget.expectedCount == 1 ? 'person' : 'people'} in this private conversation.',
            style: ZyraText.subtext(size: 12),
          ),
          const SizedBox(height: 17),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (!_available)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Members couldn't be loaded.",
                      style: ZyraText.body(size: 14),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: ZyraTapFeedback.onTap(context, _load),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _participants.length,
                separatorBuilder: (_, _) => const SizedBox(height: 9),
                itemBuilder: (_, index) =>
                    _CircleMemberRow(participant: _participants[index]),
              ),
            ),
        ],
      ),
    ),
  );
}

class _CircleMemberRow extends StatelessWidget {
  final ZyraFamilyCircleParticipant participant;

  const _CircleMemberRow({required this.participant});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: ZyraColors.surfaceFill,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: ZyraColors.surfaceBorder, width: 0.7),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ZyraColors.surfaceFill,
            border: Border.all(color: ZyraColors.surfaceEmphasisBorder),
          ),
          child: Text(
            participant.firstName.substring(0, 1).toUpperCase(),
            style: ZyraText.body(size: 15, color: ZyraColors.surfaceSignal),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(participant.firstName, style: ZyraText.body(size: 14.5)),
              const SizedBox(height: 2),
              Text(participant.roleLabel, style: ZyraText.subtext(size: 11.5)),
            ],
          ),
        ),
        if (participant.isCurrentUser)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: ZyraColors.surfaceFill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ZyraColors.surfaceEmphasisBorder),
            ),
            child: Text(
              'You',
              style: ZyraText.subtext(
                size: 10.5,
                color: ZyraColors.surfaceSignal,
              ),
            ),
          ),
      ],
    ),
  );
}

class _TodayDivider extends StatelessWidget {
  const _TodayDivider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        Expanded(child: Divider(color: ZyraColors.surfaceBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('TODAY', style: ZyraText.chapterLabel()),
        ),
        Expanded(child: Divider(color: ZyraColors.surfaceBorder)),
      ],
    ),
  );
}

enum _FamilyMessageAction { report, linkJourney }

class _FamilyMessageBubble extends StatelessWidget {
  final ZyraFamilyMessage message;
  final bool mine;
  final bool showReceipt;
  final int recipientCount;
  final VoidCallback? onReport;
  final VoidCallback? onOpenContext;
  final bool Function()? canInteract;
  final bool Function()? canOpen;
  final Widget Function(BuildContext context, Widget sheet)? sheetWrapper;
  final ZyraCircleDiscussionTopic? discussionTopic;
  final VoidCallback? onChooseJourneyReference;

  const _FamilyMessageBubble({
    required this.message,
    required this.mine,
    required this.showReceipt,
    required this.recipientCount,
    this.onReport,
    this.onOpenContext,
    this.canInteract,
    this.canOpen,
    this.sheetWrapper,
    this.discussionTopic,
    this.onChooseJourneyReference,
  });

  @override
  Widget build(BuildContext context) {
    if (message.lifecycle) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          message.body,
          textAlign: TextAlign.center,
          style: ZyraText.subtext(size: 11.5),
        ),
      );
    }
    final senderIdentity = message.senderIdentityLabel;
    return GestureDetector(
      key: ValueKey('circle_message_${message.id}'),
      onLongPress: onReport == null && onChooseJourneyReference == null
          ? null
          : () async {
              if ((canOpen ?? canInteract)?.call() == false) return;
              final action = await showModalBottomSheet<_FamilyMessageAction>(
                context: context,
                backgroundColor: ZyraColors.modalSheetSurface,
                builder: (sheetContext) {
                  bool current() =>
                      sheetContext.mounted &&
                      canInteract?.call() != false &&
                      (ModalRoute.of(sheetContext)?.isCurrent ?? false);
                  final sheet = SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onChooseJourneyReference != null)
                          ListTile(
                            key: ValueKey('circle_message_link_${message.id}'),
                            leading: const Icon(Icons.link_rounded),
                            title: Text(
                              discussionTopic == null
                                  ? 'Link a Journey'
                                  : 'Change Journey reference',
                            ),
                            onTap: ZyraTapFeedback.onTap(context, () {
                              if (current()) {
                                Navigator.of(
                                  sheetContext,
                                ).pop(_FamilyMessageAction.linkJourney);
                              }
                            }),
                          ),
                        if (onReport != null)
                          ListTile(
                            leading: const Icon(Icons.flag_outlined),
                            title: const Text('Report this message'),
                            onTap: ZyraTapFeedback.onTap(context, () {
                              if (current()) {
                                Navigator.of(
                                  sheetContext,
                                ).pop(_FamilyMessageAction.report);
                              }
                            }),
                          ),
                      ],
                    ),
                  );
                  return sheetWrapper?.call(sheetContext, sheet) ?? sheet;
                },
              );
              if ((canOpen ?? canInteract)?.call() == false) return;
              if (action == _FamilyMessageAction.report) {
                onReport?.call();
              } else if (action == _FamilyMessageAction.linkJourney) {
                onChooseJourneyReference?.call();
              }
            },
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.78,
              ),
              margin: EdgeInsets.only(
                left: mine ? 34 : 0,
                right: mine ? 0 : 34,
              ),
              padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
              decoration: BoxDecoration(
                color: ZyraColors.surfaceFill,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(mine ? 18 : 5),
                  bottomRight: Radius.circular(mine ? 5 : 18),
                ),
                border: Border.all(
                  color: mine
                      ? ZyraColors.surfaceEmphasisBorder
                      : ZyraColors.surfaceBorder,
                  width: 0.7,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!mine && senderIdentity != null) ...[
                    Text(
                      senderIdentity,
                      style: ZyraText.subtext(
                        size: 11,
                        color: ZyraColors.actionFill,
                      ),
                    ),
                    const SizedBox(height: 3),
                  ],
                  if (message.context != null) ...[
                    _MessageContextCard(
                      context: message.context!,
                      compact: true,
                      onTap: onOpenContext,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (discussionTopic != null) ...[
                    ZyraCircleTopicTag(topic: discussionTopic!),
                    const SizedBox(height: 8),
                  ],
                  Text(message.body, style: ZyraText.body(size: 13.5)),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _messageTime(message.createdAt),
                      style: ZyraText.subtext(size: 9.5),
                    ),
                  ),
                ],
              ),
            ),
            if (showReceipt)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: ZyraMessageReceipt(
                  readBy: message.readBy
                      .map(
                        (reader) => ZyraMessageReader(
                          userId: reader.userId,
                          firstName: reader.firstName,
                          roleLabel: reader.roleLabel,
                          readAt: reader.readAt,
                        ),
                      )
                      .toList(),
                  recipientCount: recipientCount,
                  canOpenReaders: canOpen ?? canInteract,
                  readersSheetWrapper: sheetWrapper,
                ),
              ),
            if (!showReceipt) const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyBanner extends StatelessWidget {
  final ZyraFamilyMessageAccess access;

  const _ReadOnlyBanner({required this.access});

  @override
  Widget build(BuildContext context) {
    final text = switch (access) {
      ZyraFamilyMessageAccess.membershipRequired =>
        'This Circle is read-only. Every current member needs paid membership to send.',
      ZyraFamilyMessageAccess.linkInactive =>
        'A linked Guardian is needed before this Circle can be used.',
      ZyraFamilyMessageAccess.blocked =>
        'Guardian Circle messaging is closed by a safety restriction.',
      _ => 'Messaging is unavailable right now.',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      color: ZyraColors.surfaceFill,
      child: Text(text, textAlign: TextAlign.center, style: ZyraText.subtext()),
    );
  }
}

/// Measure presentation space without reading a caller guard during layout.
/// The retained Circle can be laid out while an outer Page options menu is
/// covering it; authority continues to be checked by its owner and actions.
class _CircleComposerViewport extends StatelessWidget {
  const _CircleComposerViewport({required this.builder});

  final Widget Function(bool dockDiscussion) builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) => _CircleEditorHeight(
      height: constraints.maxHeight,
      keyboardOpen: View.of(context).viewInsets.bottom > 0,
      child: builder(
        View.of(context).viewInsets.bottom > 0 && constraints.maxHeight < 340,
      ),
    ),
  );
}

class _CircleEditorHeight extends InheritedWidget {
  const _CircleEditorHeight({
    required this.height,
    required this.keyboardOpen,
    required super.child,
  });

  final double height;
  final bool keyboardOpen;

  @override
  bool updateShouldNotify(_CircleEditorHeight oldWidget) =>
      height != oldWidget.height || keyboardOpen != oldWidget.keyboardOpen;
}

class ZyraFamilyMessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool busy;
  final bool contextEnabled;
  final ZyraFamilyMessageContext? selectedContext;
  final ZyraCircleDiscussionTopic? pendingDiscussionTopic;
  final VoidCallback? onRemoveDiscussionTopic;
  final VoidCallback onChooseContext;
  final VoidCallback onRemoveContext;
  final VoidCallback? onOpenContext;
  final VoidCallback onSend;
  final bool compactDiscussion;
  final String hint;
  final bool privateGuardian;
  final Widget? discussionAction;

  const ZyraFamilyMessageComposer({
    super.key,
    required this.controller,
    required this.busy,
    required this.contextEnabled,
    required this.selectedContext,
    required this.onChooseContext,
    required this.onRemoveContext,
    required this.onOpenContext,
    required this.onSend,
    this.pendingDiscussionTopic,
    this.onRemoveDiscussionTopic,
    this.compactDiscussion = false,
    this.hint = 'Message your circle',
    this.privateGuardian = false,
    this.discussionAction,
  });

  double _maximumEditorHeight(BuildContext context) {
    final viewport = context
        .dependOnInheritedWidgetOfExactType<_CircleEditorHeight>();
    if (!compactDiscussion || viewport == null) {
      return double.infinity;
    }
    final line = TextPainter(
      text: TextSpan(text: 'M', style: Theme.of(context).textTheme.titleMedium),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final minimum = line.height + 28;
    line.dispose();
    // Use the actual bounded body after SafeArea and any ancestor Scaffold's
    // keyboard resizing, rather than subtracting an already-consumed inset.
    final available = viewport.height;
    // Leave a usable transcript strip for the floating discussion action even
    // with a multi-line draft, enlarged text and the compact iPhone keyboard.
    return minimum > 160 ? minimum : (available * .24).clamp(minimum, 160);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: privateGuardian
        ? const EdgeInsets.fromLTRB(21, 6, 21, 31)
        : const EdgeInsets.fromLTRB(18, 6, 18, 12),
    child: Column(
      key: const ValueKey('guardian-circle-composer'),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (pendingDiscussionTopic case final topic?) ...[
          Container(
            key: const ValueKey('circle_pending_discussion_topic'),
            padding: const EdgeInsets.only(left: 12, right: 4),
            decoration: BoxDecoration(
              color: ZyraColors.journeyGold.withValues(alpha: .065),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ZyraColors.journeyGold.withValues(alpha: .3),
                width: .7,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    primary: false,
                    child: Text(
                      topic.sharedSummaryLabel ??
                          '${topic.isPast ? 'Past Journey' : 'Journey'} · ${topic.firstName}',
                      key: ValueKey(
                        'circle_pending_discussion_topic_${topic.id}',
                      ),
                      softWrap: false,
                      style: ZyraText.subtext(
                        size: 12,
                        color: ZyraColors.journeyGold,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('circle_remove_pending_discussion_topic'),
                  tooltip: 'Remove Journey',
                  onPressed: ZyraTapFeedback.onTap(
                    context,
                    busy ? null : onRemoveDiscussionTopic,
                  ),
                  constraints: const BoxConstraints.tightFor(
                    width: 44,
                    height: 44,
                  ),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 19,
                    color: ZyraColors.journeyGold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (selectedContext != null) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(7, 6, 4, 6),
            decoration: BoxDecoration(
              color: ZyraColors.surfaceFill,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: ZyraColors.surfaceBorder, width: 0.7),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MessageContextCard(
                    context: selectedContext!,
                    onTap: onOpenContext,
                  ),
                ),
                IconButton(
                  tooltip: 'Remove person',
                  onPressed: ZyraTapFeedback.onTap(context, onRemoveContext),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 19,
                    color: ZyraColors.foregroundSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          crossAxisAlignment: privateGuardian
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.end,
          children: [
            if (discussionAction != null) ...[
              discussionAction!,
              const SizedBox(width: 9),
            ],
            Expanded(
              child: Container(
                constraints: BoxConstraints(
                  minHeight: privateGuardian ? 46 : 52,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: ZyraColors.surfaceFill,
                  borderRadius: BorderRadius.circular(
                    privateGuardian ? 14 : 20,
                  ),
                  border: Border.all(
                    color: ZyraColors.surfaceBorder,
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (contextEnabled)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: IconButton(
                          tooltip: 'Discuss someone',
                          onPressed: ZyraTapFeedback.onTap(
                            context,
                            busy ? null : onChooseContext,
                          ),
                          visualDensity: VisualDensity.compact,
                          style: IconButton.styleFrom(
                            backgroundColor: selectedContext == null
                                ? Colors.transparent
                                : ZyraColors.actionFill.withValues(alpha: 0.14),
                          ),
                          icon: Icon(
                            Icons.person_add_alt_1_outlined,
                            size: 21,
                            color: selectedContext == null
                                ? ZyraColors.foregroundSecondary
                                : ZyraColors.surfaceSignal,
                          ),
                        ),
                      ),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: _maximumEditorHeight(context),
                        ),
                        child: TextField(
                          controller: controller,
                          style: privateGuardian
                              ? ZyraText.body(size: 13.5)
                              : null,
                          maxLength: 2000,
                          maxLines: 4,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: hint,
                            isDense: privateGuardian,
                            hintMaxLines: compactDiscussion ? 1 : null,
                            hintStyle: ZyraText.subtext(
                              size: 13.5,
                              color: ZyraColors.ink(0.48),
                            ),
                            counterText: '',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: privateGuardian ? 11 : 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 9),
            ZyraCircleSendButton(
              busy: busy,
              onSend: onSend,
              privateGuardian: privateGuardian,
            ),
          ],
        ),
      ],
    ),
  );
}

class _MessageContextPicker extends StatelessWidget {
  final List<ZyraFamilyMessageContext> contexts;

  const _MessageContextPicker({required this.contexts});

  @override
  Widget build(BuildContext context) {
    final groups = <(ZyraFamilyMessageContextKind, String)>[
      (ZyraFamilyMessageContextKind.active, 'ACTIVE JOURNEYS'),
      (ZyraFamilyMessageContextKind.potential, 'POTENTIAL'),
      (ZyraFamilyMessageContextKind.paused, 'PAUSED'),
      (ZyraFamilyMessageContextKind.ended, 'ENDED'),
    ];
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        decoration: BoxDecoration(
          color: ZyraColors.waliSheetBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: ZyraColors.surfaceBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: ZyraColors.ink(0.22),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Discuss someone', style: ZyraText.heading(size: 21)),
            const SizedBox(height: 5),
            Text(
              'Add a person to your next message so everyone knows who the conversation is about.',
              style: ZyraText.subtext(size: 12),
            ),
            const SizedBox(height: 17),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final group in groups)
                    if (contexts.any((item) => item.kind == group.$1)) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 4, 2, 7),
                        child: Text(
                          group.$2,
                          style: ZyraText.chapterLabel(
                            color: ZyraColors.foregroundMuted,
                          ),
                        ),
                      ),
                      for (final item in contexts.where(
                        (candidate) => candidate.kind == group.$1,
                      ))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: _MessageContextChoice(item: item),
                        ),
                      const SizedBox(height: 2),
                    ],
                ],
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color: ZyraColors.foregroundMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Archived history is never available here.',
                    style: ZyraText.subtext(size: 10.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageContextChoice extends StatelessWidget {
  final ZyraFamilyMessageContext item;

  const _MessageContextChoice({required this.item});

  @override
  Widget build(BuildContext context) => Material(
    color: ZyraColors.surfaceFill,
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: ZyraTapFeedback.onTap(
        context,
        () => Navigator.of(context).pop(item),
      ),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: ZyraColors.surfaceBorder, width: 0.7),
        ),
        child: Row(
          children: [
            _ContextAvatar(context: item, size: 42),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.firstName, style: ZyraText.body(size: 14.5)),
                  const SizedBox(height: 2),
                  Text(item.stateLabel, style: ZyraText.subtext(size: 11.5)),
                ],
              ),
            ),
            Icon(
              Icons.add_circle_outline_rounded,
              color: ZyraColors.surfaceSignal,
            ),
          ],
        ),
      ),
    ),
  );
}

class _MessageContextCard extends StatelessWidget {
  final ZyraFamilyMessageContext context;
  final bool compact;
  final VoidCallback? onTap;

  const _MessageContextCard({
    required this.context,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: 'Open ${this.context.firstName} ${this.context.stateLabel}',
    child: Material(
      color: ZyraColors.surfaceFill,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        key: ValueKey('open-message-context-${this.context.referenceId}'),
        onTap: ZyraTapFeedback.onTap(context, onTap),
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 9 : 8,
            vertical: compact ? 8 : 6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: ZyraColors.surfaceBorder, width: 0.6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ContextAvatar(context: this.context, size: compact ? 30 : 34),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      this.context.firstName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ZyraText.body(size: compact ? 12 : 12.5),
                    ),
                    Text(
                      this.context.stateLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ZyraText.subtext(size: compact ? 9.5 : 10),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 7),
                Icon(
                  Icons.chevron_right_rounded,
                  size: compact ? 16 : 18,
                  color: ZyraColors.foregroundMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _ContextAvatar extends StatelessWidget {
  final ZyraFamilyMessageContext context;
  final double size;

  const _ContextAvatar({required this.context, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: ZyraColors.surfaceFill,
      border: Border.all(color: ZyraColors.surfaceEmphasisBorder),
    ),
    child: Text(
      this.context.firstName.substring(0, 1).toUpperCase(),
      style: ZyraText.body(size: size * 0.36, color: ZyraColors.surfaceSignal),
    ),
  );
}

String _messageTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour == 0
      ? 12
      : local.hour > 12
      ? local.hour - 12
      : local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${local.hour >= 12 ? 'PM' : 'AM'}';
}
