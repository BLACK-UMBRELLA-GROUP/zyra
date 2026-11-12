import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

typedef ZyraProfileVideoLoader =
    Future<ZyraProfileVideoPlayback?> Function(String ownerId);

/// Bytes obtained through the viewer's authenticated download. Kept only in
/// the open surface and never shared through an image or disk cache.
class ZyraProfileVideoPlayback {
  const ZyraProfileVideoPlayback({required this.bytes, this.placeholder});

  final Uint8List bytes;
  final Widget? placeholder;
}

/// Rechecks access on open and on return from an obscuring route/background.
class ZyraProfileVideoAccess extends StatefulWidget {
  const ZyraProfileVideoAccess({
    super.key,
    required this.ownerId,
    required this.load,
    required this.builder,
  });

  final String ownerId;
  final ZyraProfileVideoLoader? load;
  final Widget Function(BuildContext, ZyraProfileVideoPlayback?) builder;

  @override
  State<ZyraProfileVideoAccess> createState() => _ZyraProfileVideoAccessState();
}

class _ZyraProfileVideoAccessState extends State<ZyraProfileVideoAccess>
    with WidgetsBindingObserver {
  ZyraProfileVideoPlayback? _video;
  int _request = 0;
  bool _current = false;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    final binding = WidgetsBinding.instance;
    _foreground =
        binding.lifecycleState == null ||
        binding.lifecycleState == AppLifecycleState.resumed;
    binding.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = ModalRoute.isCurrentOf(context) ?? true;
    if (current != _current) {
      _current = current;
      _refresh();
    }
  }

  @override
  void didUpdateWidget(covariant ZyraProfileVideoAccess oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ownerId != oldWidget.ownerId || widget.load != oldWidget.load) {
      _refresh();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _foreground) return;
    setState(() {
      _foreground = foreground;
      _refresh();
    });
  }

  void _refresh() {
    final request = ++_request;
    _video = null;
    final load = widget.load;
    if (load == null || !_current || !_foreground) return;
    unawaited(_load(load, widget.ownerId, request));
  }

  Future<void> _load(
    ZyraProfileVideoLoader load,
    String ownerId,
    int request,
  ) async {
    final ZyraProfileVideoPlayback? video;
    try {
      video = await Future.sync(() => load(ownerId));
    } catch (_) {
      // Loss of access or a failed download leaves the regular photo pages.
      return;
    }
    if (mounted && request == _request && video != null) {
      setState(() => _video = video);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _video);
}

class ZyraProfileVideoBadge extends StatelessWidget {
  const ZyraProfileVideoBadge({super.key, this.label = 'Video · no sound'});

  final String label;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: const ShapeDecoration(
        color: Color(0x73140E0A),
        shape: StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.volume_off_outlined,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: ZyraText.body(size: 11.5, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// An approved last gallery page. Creates an app-private playback file only
/// while open, then discards it when the page leaves or access is withdrawn.
class ZyraProfileVideoPage extends StatefulWidget {
  const ZyraProfileVideoPage({
    super.key,
    required this.video,
    required this.active,
    this.placeholder,
  });

  final ZyraProfileVideoPlayback video;
  final bool active;
  final Widget? placeholder;

  @override
  State<ZyraProfileVideoPage> createState() => _ZyraProfileVideoPageState();
}

class _ZyraProfileVideoPageState extends State<ZyraProfileVideoPage> {
  Future<File?>? _file;

  @override
  void initState() {
    super.initState();
    _replaceFile();
  }

  @override
  void didUpdateWidget(covariant ZyraProfileVideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active || widget.video != oldWidget.video) {
      _replaceFile();
    }
  }

  void _replaceFile() {
    _discardFile();
    final bytes = widget.video.bytes;
    if (widget.active && !kIsWeb && bytes.isNotEmpty) {
      _file = _writeTemporaryClip(bytes);
    }
  }

  static Future<File?> _writeTemporaryClip(Uint8List bytes) async {
    Directory? folder;
    try {
      folder = await Directory.systemTemp.createTemp('zyra-profile-video-');
      final file = File('${folder.path}/clip.mp4');
      return await file.writeAsBytes(bytes, flush: true);
    } on FileSystemException {
      if (folder != null) await _discardTemporaryFolder(folder);
      return null;
    }
  }

  static Future<void> _discardTemporaryFolder(Directory folder) async {
    try {
      await folder.delete(recursive: true);
    } on FileSystemException {
      // OS temporary storage may already have discarded the file.
    }
  }

  void _discardFile() {
    final file = _file;
    _file = null;
    if (file != null) {
      unawaited(
        file.then((file) async {
          if (file != null) await _discardTemporaryFolder(file.parent);
        }),
      );
    }
  }

  @override
  void dispose() {
    _discardFile();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placeholder =
        widget.video.placeholder ??
        widget.placeholder ??
        const ColoredBox(color: ZyraColors.espresso);
    return Stack(
      fit: StackFit.expand,
      children: [
        FutureBuilder<File?>(
          future: _file,
          builder: (context, snapshot) {
            final file = snapshot.connectionState == ConnectionState.done
                ? snapshot.data
                : null;
            return file == null
                ? placeholder
                : ZyraProfileVideoPlayer(
                    key: ValueKey(file.path),
                    path: file.path,
                    active: widget.active,
                    still: placeholder,
                  );
          },
        ),
        const Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Align(
            alignment: Alignment.topRight,
            child: ZyraProfileVideoBadge(),
          ),
        ),
      ],
    );
  }
}

/// Silent local playback shared by viewing, Manage photos and the trim preview.
class ZyraProfileVideoPlayer extends StatefulWidget {
  const ZyraProfileVideoPlayer({
    super.key,
    required this.path,
    required this.active,
    this.still,
    this.startMs,
    this.stillTimeMs,
    this.durationMs,
    this.playOnTapWhenReduced = true,
    this.obeyLowPower = true,
    this.reduceMotion,
  });

  final String path;
  final bool active;
  final Widget? still;
  final int? startMs;

  /// Video-relative timestamp when the source track starts later in its file.
  final int? stillTimeMs;
  final int? durationMs;
  final bool playOnTapWhenReduced;
  final bool obeyLowPower;
  final bool? reduceMotion;

  @override
  State<ZyraProfileVideoPlayer> createState() => _ZyraProfileVideoPlayerState();
}

class _ZyraProfileVideoPlayerState extends State<ZyraProfileVideoPlayer>
    with WidgetsBindingObserver {
  static const _media = MethodChannel('zyra/profile_video');

  VideoPlayerController? _controller;
  MemoryImage? _frame;
  int _frameRequest = 0;
  bool _lowPower = false;
  bool _powerKnown = false;
  int _powerRequest = 0;
  bool _foreground = true;
  bool _motionReduced = false;
  bool _routeCurrent = true;
  bool _requestedPlay = false;
  bool _ready = false;
  bool _failed = false;
  bool _syncing = false;
  bool _dirty = false;
  int? _appliedStart;

  bool get _reduced => _motionReduced || widget.obeyLowPower && _lowPower;
  bool get _visible => mounted && _foreground && _routeCurrent && widget.active;
  bool get _shouldPlay =>
      _visible &&
      (!widget.obeyLowPower || _powerKnown) &&
      (!_reduced || _requestedPlay);

  bool get _supportsPlayback =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.android);

  @override
  void initState() {
    super.initState();
    final binding = WidgetsBinding.instance;
    _foreground =
        binding.lifecycleState == null ||
        binding.lifecycleState == AppLifecycleState.resumed;
    binding.addObserver(this);
    _checkPower();
    _loadStill();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeCurrent = ModalRoute.isCurrentOf(context) ?? true;
    _updateMotionSetting();
    _updatePlayback();
  }

  void _updateMotionSetting() {
    final reduced =
        widget.reduceMotion ?? MediaQuery.disableAnimationsOf(context);
    if (reduced != _motionReduced) {
      _motionReduced = reduced;
      _requestedPlay = false;
    }
    if (!_visible) _requestedPlay = false;
  }

  @override
  void didUpdateWidget(covariant ZyraProfileVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _releaseController();
      _failed = false;
      _requestedPlay = false;
    }
    if (oldWidget.path != widget.path ||
        oldWidget.startMs != widget.startMs ||
        oldWidget.stillTimeMs != widget.stillTimeMs) {
      _discardFrame();
      _loadStill();
    }
    if (oldWidget.obeyLowPower != widget.obeyLowPower) _checkPower();
    _updateMotionSetting();
    _updatePlayback();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    setState(() {
      _foreground = state == AppLifecycleState.resumed;
      _requestedPlay = false;
      if (!_foreground && widget.obeyLowPower) {
        _powerKnown = false;
        ++_powerRequest;
      }
    });
    if (_foreground) _checkPower();
    _updatePlayback();
  }

  Future<void> _checkPower() async {
    final request = ++_powerRequest;
    if (!widget.obeyLowPower) return;
    var lowPower = false;
    try {
      lowPower = await _media.invokeMethod<bool>('lowPowerMode') ?? false;
    } on PlatformException {
      lowPower = true;
    } on MissingPluginException {
      lowPower = false;
    }
    if (!mounted || request != _powerRequest) return;
    setState(() {
      if (_lowPower != lowPower) _requestedPlay = false;
      _lowPower = lowPower;
      _powerKnown = true;
    });
    _updatePlayback();
  }

  Future<void> _loadStill() async {
    final request = ++_frameRequest;
    try {
      final frame = await _media.invokeMethod<Uint8List>('still', {
        'path': widget.path,
        'timeMs': widget.stillTimeMs ?? widget.startMs ?? 0,
      });
      if (mounted && request == _frameRequest && frame != null) {
        setState(() {
          _discardFrame();
          _frame = MemoryImage(frame);
        });
      }
    } on PlatformException {
      // The supplied poster remains visible if the frame can't be decoded.
    } on MissingPluginException {
      // Offline fixture hosts can paint the supplied poster.
    }
  }

  void _updatePlayback() {
    _dirty = true;
    if (!_syncing) unawaited(_syncPlayback());
  }

  Future<void> _syncPlayback() async {
    _syncing = true;
    try {
      while (mounted && _dirty) {
        _dirty = false;
        final current = _controller;
        if (!_shouldPlay) {
          if (current?.value.isPlaying ?? false) await current!.pause();
          continue;
        }
        if (!_supportsPlayback || _failed) continue;
        final controller = current ?? await _openController();
        if (!mounted || controller == null || controller != _controller) {
          continue;
        }
        if (!_shouldPlay) continue;
        final start = widget.startMs;
        if (start != null &&
            (_appliedStart != start || _outsideSegment(controller))) {
          _appliedStart = start;
          await controller.seekTo(Duration(milliseconds: start));
        }
        if (_shouldPlay &&
            controller == _controller &&
            !controller.value.isPlaying) {
          await controller.play();
        }
      }
    } on PlatformException {
      if (mounted) setState(() => _failed = true);
    } on MissingPluginException {
      if (mounted) setState(() => _failed = true);
    } finally {
      _syncing = false;
    }
  }

  Future<VideoPlayerController?> _openController() async {
    final controller = VideoPlayerController.file(
      File(widget.path),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller = controller;
    await controller.initialize();
    if (!mounted || _controller != controller) return null;
    await controller.setVolume(0);
    await controller.setLooping(widget.startMs == null);
    if (!mounted || _controller != controller) return null;
    controller.addListener(_watchSegment);
    setState(() => _ready = true);
    return controller;
  }

  void _watchSegment() {
    final controller = _controller;
    if (controller != null && _outsideSegment(controller)) _updatePlayback();
  }

  bool _outsideSegment(VideoPlayerController controller) {
    final start = widget.startMs;
    final duration = widget.durationMs;
    if (start == null || duration == null) return false;
    final position = controller.value.position.inMilliseconds;
    final fileEnd = controller.value.duration.inMilliseconds;
    return position < start ||
        position >= start + duration ||
        position >= fileEnd;
  }

  void _discardFrame() {
    final frame = _frame;
    _frame = null;
    if (frame != null) PaintingBinding.instance.imageCache.evict(frame);
  }

  void _releaseController() {
    final controller = _controller;
    _controller = null;
    _ready = false;
    _appliedStart = null;
    if (controller == null) return;
    controller.removeListener(_watchSegment);
    unawaited(controller.dispose());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _discardFrame();
    _releaseController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fallback =
        widget.still ?? const ColoredBox(color: ZyraColors.espresso);
    final frame = _frame;
    final controller = _controller;
    final showVideo = _ready && !_failed && _shouldPlay && controller != null;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (showVideo)
          ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          )
        else if (frame != null)
          Image(
            image: frame,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => fallback,
          )
        else
          fallback,
        if (_visible &&
            _reduced &&
            !_requestedPlay &&
            widget.playOnTapWhenReduced &&
            _supportsPlayback &&
            !_failed)
          Center(
            child: IconButton.filled(
              tooltip: 'Play video',
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xB3140E0A),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() => _requestedPlay = true);
                _updatePlayback();
              },
              icon: const Icon(Icons.play_arrow),
            ),
          ),
      ],
    );
  }
}
