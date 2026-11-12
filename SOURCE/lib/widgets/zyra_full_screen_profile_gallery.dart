import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

import '../theme/zyra_colors.dart';
import 'zyra_browse_designs.dart' show ZyraBrowsePhotoBuilder;
import 'zyra_profile_video_player.dart';
import 'zyra_profiles_components.dart';
import 'zyra_swipe_track.dart';
import 'zyra_tap_feedback.dart';

/// Full-screen member media viewer. The caller supplies admitted photos and
/// approval data and retains ownership of the return destination.
class ZyraFullScreenProfileGallery extends StatefulWidget {
  const ZyraFullScreenProfileGallery({
    super.key,
    required this.photos,
    required this.video,
    required this.photoBuilder,
    required this.canAct,
    required this.onClose,
  });

  final List<String> photos;
  final ZyraProfileVideoPlayback? video;
  final ZyraBrowsePhotoBuilder photoBuilder;
  final bool Function() canAct;
  final VoidCallback onClose;

  @override
  State<ZyraFullScreenProfileGallery> createState() =>
      _ZyraFullScreenProfileGalleryState();
}

class _ZyraFullScreenProfileGalleryState
    extends State<ZyraFullScreenProfileGallery> {
  static const _inset = 12.0;
  final _track = ZyraSwipeController();
  int _index = 0;

  int get _count => widget.photos.length + (widget.video == null ? 0 : 1);

  @override
  void didUpdateWidget(covariant ZyraFullScreenProfileGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    _index = _count == 0 ? 0 : _index.clamp(0, _count - 1);
  }

  void _select(int index) {
    if (!widget.canAct() || index < 0 || index >= _count) return;
    setState(() => _index = index);
  }

  void _turn(int direction, ValueChanged<int>? select) {
    if (_count < 2 || _track.isMoving || !widget.canAct()) return;
    final next = _index + direction;
    if (next < 0 || next >= _count) {
      select?.call(next % _count);
    } else {
      _track.animateTo(next);
    }
  }

  Widget _photo(BuildContext context, String source) => widget.photoBuilder(
    context,
    source,
    width: double.infinity,
    height: double.infinity,
    alignment: Alignment.topCenter,
  );

  Widget _page(BuildContext context, int index) {
    final video = widget.video;
    if (index < widget.photos.length) {
      return _photo(context, widget.photos[index]);
    }
    return ZyraProfileVideoPage(
      video: video!,
      active: index == _index && widget.canAct(),
      placeholder: widget.photos.isEmpty
          ? null
          : _photo(context, widget.photos.first),
    );
  }

  @override
  Widget build(BuildContext context) {
    final select = ZyraTapFeedback.onChanged<int>(
      context,
      _select,
      canAct: widget.canAct,
    );
    final close = ZyraTapFeedback.onTap(
      context,
      widget.onClose,
      canAct: widget.canAct,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        key: const ValueKey('journey-bio-profile-gallery'),
        color: const Color(0xFF1B1512),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_count > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(_inset, 49, _inset, 24),
                child: Column(
                  children: [
                    ZyraProfilesDots(
                      count: _count,
                      index: _index,
                      activeWidth: 22,
                      activeColor: const Color(0xFFC08A3A),
                      inactiveColor: const Color(0xFF9C8F84),
                      dotKey: (index) => ValueKey('bio-gallery-dot-$index'),
                    ),
                    const SizedBox(height: 1),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) => Semantics(
                          label: _index < widget.photos.length
                              ? 'Photo ${_index + 1} of ${widget.photos.length}'
                              : 'Video · no sound',
                          customSemanticsActions: {
                            if (_count > 1) ...{
                              const CustomSemanticsAction(
                                label: 'Previous',
                              ): () =>
                                  _turn(-1, select),
                              const CustomSemanticsAction(label: 'Next'): () =>
                                  _turn(1, select),
                            },
                          },
                          child: GestureDetector(
                            key: const ValueKey('bio-gallery-tap-area'),
                            behavior: HitTestBehavior.opaque,
                            excludeFromSemantics: true,
                            onTapUp: (details) => _turn(
                              details.localPosition.dx <
                                      constraints.maxWidth * .35
                                  ? -1
                                  : 1,
                              select,
                            ),
                            child: ZyraSwipeTrack(
                              key: const ValueKey('bio-gallery-swipe-track'),
                              controller: _track,
                              index: _index,
                              itemCount: _count,
                              viewportInset: _inset,
                              motionIdentity: widget.video,
                              canAct: widget.canAct,
                              onSettled: select!,
                              itemBuilder: (context, index) => ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: ColoredBox(
                                  color: const Color(0xFF3A2F28),
                                  child: _page(context, index),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Positioned(
              top: 50,
              right: 16,
              child: IconButton.filled(
                key: const ValueKey('bio-gallery-close'),
                tooltip: 'Close',
                autofocus: true,
                onPressed: close,
                style: IconButton.styleFrom(
                  foregroundColor: ZyraColors.espresso,
                  backgroundColor: const Color(0xFFFBF7F0),
                  minimumSize: const Size.square(36),
                  maximumSize: const Size.square(36),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.close, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
