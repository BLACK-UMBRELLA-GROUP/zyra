import 'dart:typed_data';

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';

import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_profile_video_player.dart';
import '../../widgets/zyra_pull_down_back_scope.dart';
import '../../widgets/zyra_tap_feedback.dart';

class ZyraProfileVideoTrimData {
  const ZyraProfileVideoTrimData({
    required this.duration,
    required this.frames,
  });

  final Duration duration;
  final List<Uint8List> frames;
}

/// The LOCK 29 V3 editor, used only when the source is longer than ten seconds.
class ZyraProfileVideoTrimScreen extends StatefulWidget {
  const ZyraProfileVideoTrimScreen({
    super.key,
    required this.load,
    required this.previewBuilder,
    required this.onUse,
    required this.onChooseAnother,
  });

  final Future<ZyraProfileVideoTrimData> Function() load;
  final Widget Function(
    BuildContext context,
    Duration start,
    Duration end,
    bool reduceMotion,
  )
  previewBuilder;
  final Future<void> Function(Duration start) onUse;
  final VoidCallback onChooseAnother;

  @override
  State<ZyraProfileVideoTrimScreen> createState() =>
      _ZyraProfileVideoTrimScreenState();
}

const _window = Duration(seconds: 10);
const _second = Duration(seconds: 1);
const _frameCount = 10;

String _timestamp(Duration duration) {
  final rounded = (duration.inMilliseconds / 1000).round();
  final seconds = (rounded % 60).toString().padLeft(2, '0');
  return '${rounded ~/ 60}:$seconds';
}

class _ZyraProfileVideoTrimScreenState
    extends State<ZyraProfileVideoTrimScreen> {
  late final _media = Future.sync(widget.load).then((media) {
    if (media.duration <= _window || media.frames.length != _frameCount) {
      throw StateError('Invalid profile video trim data');
    }
    return media;
  });
  final _routeIdentity = Object();
  late final VoidCallback _back = _close;
  var _start = Duration.zero;
  var _exporting = false;
  var _failed = false;

  void _close() => Navigator.of(context).maybePop();

  Future<void> _use() async {
    if (_exporting) return;
    final start = _start;
    setState(() => _exporting = true);
    try {
      await widget.onUse(start);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return PopScope(
      canPop: !_exporting,
      child: ZyraPullDownBackScope(
        routeIdentity: _routeIdentity,
        onBack: _back,
        enabled: !_exporting,
        paintBackground: false,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: DecoratedBox(
            decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 15, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Center(
                          widthFactor: 1,
                          child: Semantics(
                            header: true,
                            child: Text(
                              'Choose 10 seconds',
                              style: ZyraText.heading(size: 28).copyWith(
                                fontWeight: FontWeight.w300,
                                letterSpacing: .2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: FutureBuilder<ZyraProfileVideoTrimData>(
                        future: _media,
                        builder: (context, snapshot) {
                          if (_failed || snapshot.hasError) {
                            return _Unavailable(
                              onChooseAnother: widget.onChooseAnother,
                            );
                          }
                          final media = snapshot.data;
                          if (_exporting || media == null) {
                            return _Preparing(reduceMotion: reduceMotion);
                          }
                          return _ready(media, reduceMotion);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ready(ZyraProfileVideoTrimData media, bool reduceMotion) {
    final end = _start + _window;
    final timeStyle = ZyraText.subtext(size: 12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Slide the gold frame to pick your best 10 seconds. '
          'It plays without sound.',
          style: ZyraText.subtext(),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            key: const ValueKey('profile-video-trim-preview'),
            decoration: BoxDecoration(
              color: const Color(0xFFD9CBB5),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F3E2E1E),
                  blurRadius: 26,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Builder(
                  builder: (context) =>
                      widget.previewBuilder(context, _start, end, reduceMotion),
                ),
                PositionedDirectional(
                  top: 16,
                  end: 16,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: ZyraProfileVideoBadge.background,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.volume_off_outlined,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'No sound',
                            style: ZyraText.subtext(
                              size: 11.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                '${_timestamp(_start)} – ${_timestamp(end)}',
                style: timeStyle,
              ),
            ),
            Flexible(
              child: Text(
                'Video ${_timestamp(media.duration)}',
                style: timeStyle,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Filmstrip(
          media: media,
          start: _start,
          onChanged: (start) => setState(() => _start = start),
        ),
        const SizedBox(height: 14),
        _GoldButton(label: 'Use these 10 seconds', height: 50, onPressed: _use),
        const SizedBox(height: 14),
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 46),
            foregroundColor: ZyraColors.espresso,
            textStyle: ZyraText.subtext(size: 13),
          ),
          onPressed: ZyraTapFeedback.onTap(context, widget.onChooseAnother),
          child: const Text('Choose another video'),
        ),
      ],
    );
  }
}

class _Filmstrip extends StatefulWidget {
  const _Filmstrip({
    required this.media,
    required this.start,
    required this.onChanged,
  });

  final ZyraProfileVideoTrimData media;
  final Duration start;
  final ValueChanged<Duration> onChanged;

  @override
  State<_Filmstrip> createState() => _FilmstripState();
}

class _FilmstripState extends State<_Filmstrip> {
  double _grabOffset = 0;

  Duration _clamp(Duration start) {
    final max = widget.media.duration - _window;
    return Duration(
      microseconds: start.inMicroseconds.clamp(0, max.inMicroseconds),
    );
  }

  void _select(double position, double width) {
    final selected = _clamp(
      Duration(
        microseconds: (position / width * widget.media.duration.inMicroseconds)
            .round(),
      ),
    );
    if (selected != widget.start) widget.onChanged(selected);
  }

  String _spoken(Duration start) => 'Start ${_timestamp(start)}, 10 seconds';

  @override
  Widget build(BuildContext context) {
    final earlier = _clamp(widget.start - _second);
    final later = _clamp(widget.start + _second);
    return Semantics(
      slider: true,
      value: _spoken(widget.start),
      increasedValue: later == widget.start ? null : _spoken(later),
      decreasedValue: earlier == widget.start ? null : _spoken(earlier),
      onIncrease: later == widget.start ? null : () => widget.onChanged(later),
      onDecrease: earlier == widget.start
          ? null
          : () => widget.onChanged(earlier),
      child: SizedBox(
        key: const ValueKey('profile-video-filmstrip'),
        height: 56,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final total = widget.media.duration.inMicroseconds;
            final left = width * widget.start.inMicroseconds / total;
            final frameWidth = width * _window.inMicroseconds / total;
            return GestureDetector(
              excludeFromSemantics: true,
              behavior: HitTestBehavior.opaque,
              dragStartBehavior: DragStartBehavior.down,
              onTapUp: (details) => _select(details.localPosition.dx, width),
              onHorizontalDragStart: (details) {
                final x = details.localPosition.dx;
                _grabOffset = x >= left && x <= left + frameWidth
                    ? x - left
                    : 0;
                _select(x - _grabOffset, width);
              },
              onHorizontalDragUpdate: (details) =>
                  _select(details.localPosition.dx - _grabOffset, width),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Row(
                      textDirection: TextDirection.ltr,
                      spacing: 2,
                      children: [
                        for (final bytes in widget.media.frames)
                          Expanded(
                            child: Image.memory(
                              bytes,
                              fit: BoxFit.cover,
                              height: 56,
                              opacity: const AlwaysStoppedAnimation(.85),
                              excludeFromSemantics: true,
                              errorBuilder: (_, _, _) =>
                                  const ColoredBox(color: Color(0xFFD9CBB5)),
                            ),
                          ),
                      ],
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: left,
                      child: const ColoredBox(color: Color(0x8CFBF7F0)),
                    ),
                    Positioned(
                      left: left + frameWidth,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: const ColoredBox(color: Color(0x8CFBF7F0)),
                    ),
                    Positioned(
                      left: left,
                      top: 0,
                      bottom: 0,
                      width: frameWidth,
                      child: DecoratedBox(
                        key: const ValueKey('profile-video-trim-window'),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            width: 3,
                            color: ZyraColors.goldTextFill,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Preparing extends StatelessWidget {
  const _Preparing({required this.reduceMotion});

  final bool reduceMotion;

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(
              value: reduceMotion ? .25 : null,
              strokeWidth: 3,
              backgroundColor: ZyraColors.divider,
              color: ZyraColors.journeyGold,
            ),
          ),
          const SizedBox(height: 12),
          Text('Preparing your video…', style: ZyraText.subtext()),
        ],
      ),
    ),
  );
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.onChooseAnother});

  final VoidCallback onChooseAnother;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: ZyraColors.journeyGold.withValues(alpha: .6),
            ),
          ),
          child: const Icon(
            Icons.volume_off_outlined,
            color: ZyraColors.journeyGold,
            size: 24,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'This video couldn’t be opened',
          textAlign: TextAlign.center,
          style: ZyraText.heading(
            size: 19,
          ).copyWith(fontWeight: FontWeight.w300),
        ),
        const SizedBox(height: 6),
        Text(
          'Try another video, or save it to your phone first.',
          textAlign: TextAlign.center,
          style: ZyraText.subtext(),
        ),
        const SizedBox(height: 16),
        _GoldButton(
          label: 'Choose another video',
          height: 46,
          onPressed: onChooseAnother,
        ),
      ],
    ),
  );
}

class _GoldButton extends StatelessWidget {
  const _GoldButton({
    required this.label,
    required this.height,
    required this.onPressed,
  });

  final String label;
  final double height;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const ShapeDecoration(
      shape: StadiumBorder(),
      shadows: [
        BoxShadow(
          color: Color(0x40C08A3A),
          offset: Offset(0, 8),
          blurRadius: 18,
        ),
      ],
    ),
    child: FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: Size(0, height),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        backgroundColor: ZyraColors.primaryAction,
        foregroundColor: ZyraColors.onPrimaryAction,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const StadiumBorder(),
        side: BorderSide.none,
        textStyle: ZyraText.button(
          size: 14,
        ).copyWith(fontWeight: FontWeight.w500, letterSpacing: 0),
      ),
      onPressed: ZyraTapFeedback.onTap(context, onPressed),
      child: Text(label),
    ),
  );
}
