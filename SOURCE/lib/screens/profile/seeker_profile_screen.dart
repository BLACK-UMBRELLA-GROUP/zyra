// FULL PROFILE — read-only, for someone you are already in a Journey with.
//
// Founder, 2026-08-10: "we need somewhere where the user can view full
// profile which doesn't take them to browse page.. but I want somewhere they
// can see full photo".
//
// WHY THIS IS A NEW SCREEN AND NOT A REUSE. Before today there was no way to
// look at another person's profile except Browse. "View profile" elsewhere in
// the app does not open a profile at all — it switches the shell to the Browse
// tab and parks the profile there (browse_screen.dart:399,
// connections_screen.dart:87). That is fine for a suggestion you are about to
// decide on, and wrong for someone you are mid-Journey with: Browse is the
// DECIDING surface, carrying Save / Consider / Pass. Sending a Seeker there to
// look at the person they are ALREADY in a Journey with offers them decisions
// they have already made, on a screen whose whole job is making them.
//
// So: no actions on this screen. It is a place to look, not to choose.
//
// AMENDED 2026-08-12 (Founder, Option A of the row-tap mockups: "the row
// IS the person… execute all of it"): the JOURNEY LIST rows now open this
// screen for Potential, Paused and Ended people, and those states carry
// their actions WITH them — an optional [actionBar] rendered at the foot,
// and an optional [stateLabel] chip at the top right. The screen itself
// stays action-agnostic: it renders what it is handed and never decides.
// The Journey header's own "Profile" pill passes neither, so mid-Journey
// viewing is exactly the no-actions place it always was. Browse remains
// the only deciding surface for people you are NOT yet matched with.
//
// PHOTO NAVIGATION MATCHES BROWSE — Founder, 2026-08-10. This was briefly a
// swipeable PageView with dots across the top, which is a second convention
// for the one gesture people use most in this app. Browse settled it long ago:
//   • TAP the left or right half to step back or forward
//   • a VERTICAL dot column on the LEFT edge, middle-aligned
//   • 7px dots, 3px apart, white when active, white32 when not, hairline
//     white30 border so they read on a pale photograph
// Copied to the pixel from browse_screen.dart's own indicator rather than
// approximated, because "nearly the same" is how two conventions start.
//
// WHAT IT CAN SHOW is bounded by SeekerProfile — id, firstName, surnameLine,
// age, city, photos, gender. No bio, occupation or education. Stated rather
// than padded with placeholders: an empty "About" section would imply the data
// exists and is missing, when it has never been modelled.
//
// PHOTO VISIBILITY IS ENFORCED SERVER-SIDE. profile_photos is filtered by
// zyra_can_view_profile, verified by impersonation on 2026-08-08. This screen
// renders what it was handed; it is not a gate and must never become one.

import 'package:flutter/material.dart';
import '../../models/seeker_profile.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_profile_name_block.dart';
import '../../widgets/zyra_profile_image.dart';

class SeekerProfileScreen extends StatefulWidget {
  final SeekerProfile profile;

  /// Small chip at the top right — "Paused by Aisha · 3 months",
  /// "Potential", "Ended in June". Null (the Journey header's use) shows
  /// nothing.
  final String? stateLabel;

  /// The state's actions, rendered at the foot over the photo. The
  /// CALLER owns every button in it (what they say, what they pop, what
  /// they push) — this screen only makes room. Null = the original
  /// look-only screen, unchanged.
  final Widget? actionBar;

  /// A line under the name — who put this person forward.
  ///
  /// ADDED 2026-08-13 (DR-ZYRA-160, Founder: "when profile card is
  /// opened show somewhere the text suggested by (then user)"). It
  /// replaces the [stateLabel] chip the introduction flow used to pass,
  /// and the position is the point of the change: a chip in the top
  /// right sat on the photo, away from the person it describes. Under
  /// the name it reads as part of who they are — which is what a
  /// Guardian's introduction is.
  ///
  /// Same shield glyph the Connections card uses for the same fact, so
  /// the two surfaces say it the same way.
  final String? suggestedBy;

  const SeekerProfileScreen(
      {super.key,
      required this.profile,
      this.stateLabel,
      this.actionBar,
      this.suggestedBy});

  @override
  State<SeekerProfileScreen> createState() => _SeekerProfileScreenState();
}

class _SeekerProfileScreenState extends State<SeekerProfileScreen> {
  int _photoIndex = 0;

  /// Left half steps back, right half steps forward. Same rule and same
  /// wrap behaviour as browse_screen.dart's `_tapPhoto`: forward wraps to
  /// the first photo, back STOPS at the first rather than wrapping to the
  /// last. That asymmetry is deliberate there and is kept here — going
  /// forward is browsing, going back is correcting, and a correction that
  /// jumps you to the end is not a correction.
  void _tapPhoto(TapUpDetails details, double width) {
    final photos = widget.profile.photos;
    if (photos.length <= 1) return;
    final goRight = details.localPosition.dx > width / 2;
    setState(() {
      if (goRight) {
        _photoIndex = _photoIndex >= photos.length - 1 ? 0 : _photoIndex + 1;
      } else {
        _photoIndex = _photoIndex <= 0 ? 0 : _photoIndex - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final photos = p.photos;
    // Guard the index the way browse_screen learned to: a stale index against
    // a shorter list threw there once, and the fix was to clamp at the read
    // rather than trust every writer.
    final safeIndex = _photoIndex < photos.length ? _photoIndex : 0;

    return Scaffold(
      // Black, not the gender gradient. Every other surface in the app is
      // gradient-backed; here the photo IS the content, and a gradient behind
      // a full-bleed image is a gradient nobody sees, tinting the edges of
      // someone's face for no reason.
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          onTapUp: (d) => _tapPhoto(d, constraints.maxWidth),
          child: Stack(
            children: [
              Positioned.fill(
                child: ZyraProfileImage(
                  photos.isEmpty ? '' : photos[safeIndex],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),

              // Legibility scrim. The name sits over a photograph nobody chose
              // for its contrast, so the text needs its own background rather
              // than hoping the image is dark at the bottom.
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    height: 260,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xE6000000)],
                      ),
                    ),
                  ),
                ),
              ),

              // LEFT-SIDE VERTICAL DOTS — browse_screen.dart's indicator,
              // matched exactly. Only when there is more than one photo: a
              // single dot says "there is more" and there is not.
              if (photos.length > 1)
                Positioned(
                  left: 16, top: 0, bottom: 0,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(photos.length, (i) {
                        final active = i == safeIndex;
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 0.5),
                            color: active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.32),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

              Positioned(
                // The name block lifts to make room when a state's action
                // bar rides along (journey rows); look-only callers keep
                // the original resting place.
                left: 20, right: 20,
                bottom: widget.actionBar == null ? 32 : 132,
                child: IgnorePointer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // THE SHARED BLOCK — DR-ZYRA-163. The surname
                      // had its own line here, per the 2026-07-26 Browse
                      // review; Browse itself moved it inline on
                      // 2026-08-13 (DR-ZYRA-162) and this followed it,
                      // by using the same widget rather than by being
                      // edited to match. It also gains the two-layer
                      // photo shadow, which was private to Browse and so
                      // never reached this screen at all.
                      ZyraProfileNameBlock(profile: p),
                      if ((widget.suggestedBy ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined,
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.75)),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Suggested by ${widget.suggestedBy!.trim()}',
                                style: ZyraText.subtext(
                                    size: 12.5,
                                    color:
                                        Colors.white.withValues(alpha: 0.85)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              Positioned(
                top: 0, left: 4,
                child: SafeArea(
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 26),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),

              if (widget.stateLabel != null)
                Positioned(
                  top: 8, right: 16,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0x59140C1A),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22)),
                      ),
                      child: Text(widget.stateLabel!,
                          style: ZyraText.subtext(
                              size: 10.5,
                              color: Colors.white.withValues(alpha: 0.9))),
                    ),
                  ),
                ),

              if (widget.actionBar != null)
                Positioned(
                  left: 16, right: 16, bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: widget.actionBar!,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
