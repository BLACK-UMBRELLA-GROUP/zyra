// Renders a profile photo, whether it is a real URL or a dev colour block.
//
// ADDED 2026-08-03 with the 200 colour-block test profiles (Founder: "just
// put black / blue / green solid colours etc to represent more than one
// photo").
//
// ONE place decides, deliberately. `Image.network` was called directly in
// six files; without this, adding colour support would have meant six
// copies of the same conditional and a seventh appearing the next time
// somebody rendered a photo. Every one of those call sites now goes
// through here, so a colour block works everywhere a photograph does —
// Browse, the Connections cards, Journey tiles, Chat headers, the Guardian
// views — without any of them knowing the concept exists.
//
// The error fallback is also unified. Three of those six call sites had a
// slightly different errorBuilder and two had none at all, so a broken
// image showed as a dark rectangle in some places and Flutter's grey
// broken-image glyph in others.

// ── THE SECOND LOADING SCREEN — fixed 2026-08-08.
//
// Founder, having just had the Material spinner removed everywhere else:
// "there's still a 2nd delay where the loading page with 4 dots switched to
// another loading page with moving circle."
//
// This file was it, and it was NOT on the list of screen-level loaders I
// migrated — I had classified it as an "image placeholder" and deliberately
// left it alone. That classification was wrong, and it was wrong for a
// reason worth writing down: I judged it by WHAT IT IS (a loadingBuilder on
// an Image) instead of BY HOW BIG IT RENDERS. The only call site that
// passes `showLoader: true` is the Browse card, where the photo is
// effectively the whole screen — so a 34px spinner centred in it is,
// from the user's seat, a full loading screen. Same event, same treatment.
//
// The size guard below is what that mistake should have been in the first
// place: the indicator now depends on the space it actually gets, not on
// which widget happens to own it.

import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import 'zyra_loading.dart';

class ZyraProfileImage extends StatelessWidget {
  final String photo;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Shows a spinner while the image loads.
  final bool showLoader;

  const ZyraProfileImage(
    this.photo, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.showLoader = false,
  });

  @override
  Widget build(BuildContext context) {
    // The colour-block branch was removed 2026-08-04 with the 200-profile
    // dev deck. Every photo is now a real signed Storage URL.
    //
    // ADDED 2026-08-05. An empty URL reaches Image.network as a request that
    // fails asynchronously, so the placeholder appears a frame late and, on a
    // full-screen card, reads as a broken screen rather than a missing photo.
    // Answering it here is both faster and quieter. It should now be rare —
    // the storage-read policy fix means photos resolve — but "rare" is not
    // "never", and a person with no viewable photo must still render.
    if (photo.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: const ColoredBox(color: ZyraColors.luxuryDarkPurple),
      );
    }

    return Image.network(
      photo,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: !showLoader
          ? null
          // ── SEAMLESS, 2026-08-08 (second pass). Founder, on the screen
          // recording: "the loading is a bit buggy, can you fix that also
          // so it's seamless."
          //
          // Two faults, both mine, both from the pass an hour earlier:
          //
          //   1. I painted #1A1220 behind the dots while loading, to match
          //      the empty and error states. Those are PERMANENT states, so
          //      a solid block is right for them. This one is TRANSIENT, and
          //      the block turned the handover into pink -> near-black ->
          //      photo. The recording shows exactly that: a hard cut to a
          //      dark screen for about a second in the middle of a launch
          //      that was otherwise smooth. Nothing is painted now, so the
          //      card keeps the member's gradient the whole way through.
          //
          //   2. The photo then appeared in one frame. AnimatedSwitcher
          //      cross-fades it in over the dots instead.
          //
          // Not frameBuilder, which is the usual way to fade an image in:
          // while loadingBuilder is showing the placeholder, the
          // frameBuilder subtree is not mounted, so its first build already
          // has a frame and the fade never plays. Doing it here means the
          // switch happens where both states actually exist.
          : (context, child, progress) => AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                // ── StackFit.passthrough IS LOAD-BEARING. Founder,
                // 2026-08-08: "the photo in browse page isn't taking up
                // the whole screen."
                //
                // That was this AnimatedSwitcher, added minutes earlier.
                // Its DEFAULT layoutBuilder is a Stack with LOOSE
                // constraints; the code it replaced returned `child`
                // untouched, so the image inherited the TIGHT constraints
                // Browse's `Stack(fit: StackFit.expand)` hands down. An
                // Image with `fit: BoxFit.cover` and no explicit width or
                // height fills tight constraints and letterboxes itself
                // inside loose ones — so the card gained a border of
                // background on all four sides.
                //
                // passthrough, not expand: expand would force tight
                // constraints even where the parent gave unbounded ones
                // (a scrollable, an intrinsic-height row) and throw.
                // passthrough hands the parent's own constraints down
                // unchanged, which is exactly the behaviour that existed
                // before this switcher was introduced.
                layoutBuilder: (current, previous) => Stack(
                  fit: StackFit.passthrough,
                  children: [...previous, if (current != null) current],
                ),
                child: progress == null
                    ? KeyedSubtree(key: const ValueKey('photo'), child: child)
                    : SizedBox(
                        key: const ValueKey('placeholder'),
                        width: width,
                        height: height,
                        // LayoutBuilder, not the width/height fields: both
                        // are usually null here (the image fills its
                        // parent), so the fields say nothing about the
                        // space this actually gets. The constraints do.
                        child: LayoutBuilder(
                          builder: (context, c) {
                            final roomy = c.maxWidth >= 120 && c.maxHeight >= 60;
                            // On a small avatar, nothing at all. A loading
                            // animation inside a 40px circle is noise.
                            return roomy
                                ? const ZyraLoading()
                                : const SizedBox.shrink();
                          },
                        ),
                      ),
              ),
      errorBuilder: (_, _, _) => SizedBox(
        width: width,
        height: height,
        child: const ColoredBox(color: ZyraColors.luxuryDarkPurple),
      ),
    );
  }
}
