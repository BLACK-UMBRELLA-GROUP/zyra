// Match Notification — full-screen moment per MATCH_UX_SPEC_CURRENT_
// VERSION_V1.md §Match Notification - Moment Design. "Warm, calm, human
// — not a game mechanic." Both photos circular/softened, first names
// only, "A Potential Journey has been created." Primary CTA "View
// match" -> Matches tab. Secondary "Later" -> dismiss, stay on Browse.
// No confetti, no sound, gentle fade-in only.

import 'package:flutter/material.dart';
import '../../models/seeker_profile.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';

class MatchNotificationScreen extends StatefulWidget {
  final SeekerProfile matchedWith;
  final VoidCallback onViewMatch;

  const MatchNotificationScreen({super.key, required this.matchedWith, required this.onViewMatch});

  @override
  State<MatchNotificationScreen> createState() => _MatchNotificationScreenState();
}

class _MatchNotificationScreenState extends State<MatchNotificationScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 2026-07-25: gender-matched gradient (DR-ZYRA-094) — see
        // ZyraColors.genderGradient() doc comment.
        decoration: BoxDecoration(gradient: ZyraColors.genderGradient(AppState.instance.gender)),
        child: FadeTransition(
          opacity: _fade,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 110,
                    width: 170,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          child: _CirclePhoto(url: widget.matchedWith.photoUrl),
                        ),
                        Positioned(
                          right: 0,
                          child: _CirclePhoto(url: 'https://picsum.photos/seed/you/300/300'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('You and ${widget.matchedWith.firstName} matched.', style: ZyraText.heading(size: 22), textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Text('A Potential Journey has been created.', style: ZyraText.subtext(), textAlign: TextAlign.center),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: ZyraColors.accentBg,
                        border: Border.all(color: ZyraColors.accentBorder, width: 1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(50),
                          onTap: widget.onViewMatch,
                          child: Center(child: Text('View match', style: ZyraText.button())),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Later', style: ZyraText.subtext(size: 13, color: Colors.white70)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CirclePhoto extends StatelessWidget {
  final String url;
  const _CirclePhoto({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 2),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
    );
  }
}
