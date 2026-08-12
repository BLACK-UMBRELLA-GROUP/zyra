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
import '../../widgets/zyra_profile_image.dart';

class SeekerProfileScreen extends StatefulWidget {
  final SeekerProfile profile;
  const SeekerProfileScreen({super.key, required this.profile});

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
                left: 20, right: 20, bottom: 32,
                child: IgnorePointer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.firstName, style: ZyraText.heading(size: 30)),
                      // Surname on its own line, per the Founder's 2026-07-26
                      // Browse review — "put surname under first name".
                      // surnameLine is a display string, not a lastName: it may
                      // already hold "middle name + surname" together.
                      if ((p.surnameLine ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(p.surnameLine!.trim(),
                            style: ZyraText.heading(
                                size: 20,
                                color: Colors.white.withValues(alpha: 0.88))),
                      ],
                      const SizedBox(height: 8),
                      Text('${p.age} · ${p.city}',
                          style: ZyraText.body(
                              size: 15,
                              color: Colors.white.withValues(alpha: 0.85))),
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
            ],
          ),
        ),
      ),
    );
  }
}
