// Send feedback.
//
// NEW 2026-08-07. Founder: "in setting we need a feedback section where we
// can improve the app from users requests."
//
// SEPARATE FROM HELP & SUPPORT, deliberately. Help is for someone who is
// stuck and wants an answer; it ends in an email address because that is
// what a stuck person needs. This is for someone who is fine and has a
// thought, and those two people should not be sent down the same corridor.
//
// THREE CATEGORIES, NOT SEVEN. A long list makes someone stop and classify
// before they can speak, and the classification is worth less than the
// sentence. Idea, Problem, Other covers the split that actually changes
// what happens next.
//
// NO SUBJECT LINE, no attachments, no "steps to reproduce". Every one of
// those raises the cost of saying something, and the whole value here is
// volume of honest small remarks. app_version, platform and screen are
// captured silently — the three things that make a report actionable and
// the three things a user should never be asked to type.

import 'package:flutter/material.dart';

import '../../services/zyra_feedback_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _controller = TextEditingController();
  ZyraFeedbackCategory _category = ZyraFeedbackCategory.idea;
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sending = true);

    final res = await ZyraFeedbackService.submit(
      category: _category,
      message: _controller.text,
      screen: 'settings/feedback',
    );
    if (!mounted) return;
    setState(() => _sending = false);

    if (res == ZyraFeedbackResult.sent) {
      // The screen changes rather than a snackbar firing over a form the
      // user might then submit again. Sending twice by accident is the
      // most likely mistake here, and removing the form removes it.
      setState(() => _sent = true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (res) {
          ZyraFeedbackResult.empty => 'Write something first.',
          ZyraFeedbackResult.tooLong =>
            "That's longer than we can take — try trimming it down.",
          ZyraFeedbackResult.rateLimited =>
            "You've sent a few already — give it an hour and send more.",
          _ => "That didn't send. Please try again.",
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Send feedback', style: ZyraText.heading(size: 17)),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: ZyraColors.genderGradient(AppState.instance.gender),
        ),
        child: SafeArea(
          child: _sent ? _thanks() : _form(),
        ),
      ),
    );
  }

  Widget _thanks() => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline,
                  size: 46, color: Colors.white54),
              const SizedBox(height: 18),
              Text('Thank you', style: ZyraText.heading(size: 19)),
              const SizedBox(height: 10),
              Text(
                // No promise of a reply. There is no in-app messaging and
                // no support rota, so "we'll get back to you" would be a
                // thing we cannot do — and the one place a user would
                // reasonably expect us to keep our word.
                'A real person reads every one of these. We may not reply, '
                'but it does get read.',
                textAlign: TextAlign.center,
                style: ZyraText.subtext(size: 13, color: Colors.white54),
              ),
              const SizedBox(height: 30),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Done',
                    style: ZyraText.body(size: 15, color: Colors.white)),
              ),
            ],
          ),
        ),
      );

  Widget _form() => ListView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Text(
            'Tell us what would make ZYRA better. Small things count — the '
            'wording that confused you is as useful as the feature you want.',
            style: ZyraText.subtext(size: 12.5, color: Colors.white54),
          ),
          const SizedBox(height: 22),

          Text('WHAT KIND?', style: ZyraText.chapterLabel(color: Colors.white54)),
          const SizedBox(height: 10),
          Row(
            children: ZyraFeedbackCategory.values.map((c) {
              final selected = c == _category;
              return Padding(
                padding: const EdgeInsets.only(right: 9),
                child: GestureDetector(
                  onTap: () => setState(() => _category = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 17, vertical: 9),
                    decoration: BoxDecoration(
                      color: selected
                          ? ZyraColors.accentBg
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? ZyraColors.accentBorder
                            : Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Text(
                      c.label,
                      style: ZyraText.body(
                        size: 14,
                        color: selected ? Colors.white : Colors.white54,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: TextField(
              controller: _controller,
              maxLines: 8,
              minLines: 5,
              maxLength: 4000,
              style: ZyraText.body(size: 15, color: Colors.white),
              cursorColor: Colors.white70,
              decoration: InputDecoration(
                border: InputBorder.none,
                counterStyle:
                    ZyraText.subtext(size: 11, color: Colors.white24),
                hintText: switch (_category) {
                  ZyraFeedbackCategory.idea =>
                    'What would you like ZYRA to do?',
                  ZyraFeedbackCategory.problem =>
                    'What happened, and what did you expect instead?',
                  ZyraFeedbackCategory.other => 'Tell us anything.',
                },
                hintStyle:
                    ZyraText.subtext(size: 14, color: Colors.white24),
              ),
            ),
          ),
          const SizedBox(height: 18),

          GestureDetector(
            onTap: _sending ? null : _send,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ZyraColors.accentBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ZyraColors.accentBorder),
              ),
              child: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white70),
                    )
                  : Text('Send',
                      style: ZyraText.body(size: 15, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),

          // Said before they type, not after. Someone about to describe a
          // problem deserves to know what goes with it.
          Text(
            'We also send your app version, whether you are on iOS or '
            'Android, and which screen you were on. Nothing else.',
            style: ZyraText.subtext(size: 11.5, color: Colors.white30),
          ),
        ],
      );
}
