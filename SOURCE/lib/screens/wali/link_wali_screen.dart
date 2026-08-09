// Shared "Link a Guardian" / "Link a Seeker" screen — reachable from both
// the Seeker's own Profile (asWali: false) and the Guardian's own Profile
// (asWali: true). Shows existing links, and — when none exist — both
// directions of the linking mechanism: generate an invite for the
// other party, or enter a code someone already sent. See
// ZyraWaliLinkService's doc comment for the underlying design.

import 'package:flutter/material.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import 'accept_wali_invite_screen.dart';
import '../../widgets/zyra_loading.dart';

class LinkWaliScreen extends StatefulWidget {
  final bool asWali;
  const LinkWaliScreen({super.key, required this.asWali});

  @override
  State<LinkWaliScreen> createState() => _LinkWaliScreenState();
}

class _LinkWaliScreenState extends State<LinkWaliScreen> {
  bool _loading = true;
  List<WaliLinkedPerson> _linked = [];
  String? _generatedCode;
  bool _generating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final linked = await ZyraWaliLinkService.fetchLinkedPeople(asWali: widget.asWali);
    if (!mounted) return;
    setState(() {
      _linked = linked;
      _loading = false;
    });
  }

  Future<void> _generateInvite() async {
    setState(() {
      _generating = true;
      _error = null;
    });
    final token = await ZyraWaliLinkService.createInvite();
    if (!mounted) return;
    setState(() {
      _generating = false;
      if (token == null) {
        _error = "Couldn't generate a code. Tap to try again.";
      } else {
        _generatedCode = token;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final otherLabel = widget.asWali ? 'Seeker' : 'Guardian';
    return Scaffold(
      // FIXED 2026-08-01 (Founder: "there should be no purple at top, it
      // should blend the pink/purple colour... that should be across all
      // things"). Same fix notifications_screen.dart got on 2026-07-27:
      // without this the transparent AppBar shows the Scaffold's own flat
      // background through, cutting the gender gradient off with a hard
      // purple strip. Body content compensates with SafeArea, which still
      // clears the status bar.
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Link a $otherLabel', style: ZyraText.heading(size: 17)),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: Container(
        // 2026-07-25: gender-matched gradient (DR-ZYRA-094) — see
        // ZyraColors.genderGradient() doc comment.
        decoration: BoxDecoration(gradient: ZyraColors.genderGradient(AppState.instance.gender)),
        child: SafeArea(
          child: _loading
              ? const ZyraLoading()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                  children: [
                    if (_linked.isEmpty)
                      ZyraEmptyState(
                        icon: Icons.link,
                        message: "No $otherLabel linked yet. Invite one, or enter a code they've sent you.",
                      )
                    else ...[
                      Text('LINKED', style: ZyraText.chapterLabel(color: Colors.white54)),
                      const SizedBox(height: 10),
                      ..._linked.map(
                        (p) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: Colors.white54, size: 18),
                              const SizedBox(width: 10),
                              Text(p.firstName, style: ZyraText.body(size: 14, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    Text('INVITE A ${otherLabel.toUpperCase()}', style: ZyraText.chapterLabel(color: Colors.white54)),
                    const SizedBox(height: 10),
                    if (_generatedCode == null)
                      _ActionButton(
                        label: _generating ? 'Generating…' : 'Generate Invite Code',
                        onTap: _generating ? null : _generateInvite,
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ZyraColors.iconButtonBg,
                          border: Border.all(color: ZyraColors.iconButtonBorder, width: 0.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Share this code with your $otherLabel:', style: ZyraText.subtext(size: 12)),
                            const SizedBox(height: 8),
                            Text(_generatedCode!, style: ZyraText.heading(size: 22).copyWith(letterSpacing: 4)),
                            const SizedBox(height: 8),
                            Text(
                              "Sharing (SMS, email, WhatsApp) isn't wired up yet in this preview build — copy and send this code however works today.",
                              style: ZyraText.subtext(size: 11, color: Colors.white38),
                            ),
                          ],
                        ),
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      ZyraErrorBanner(message: _error!, onRetry: _generateInvite, onDismiss: () => setState(() => _error = null)),
                    ],
                    const SizedBox(height: 28),
                    Text('HAVE A CODE?', style: ZyraText.chapterLabel(color: Colors.white54)),
                    const SizedBox(height: 10),
                    _ActionButton(
                      label: 'Enter Invite Code',
                      outlined: true,
                      onTap: () async {
                        final linked = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(builder: (_) => const AcceptWaliInviteScreen()),
                        );
                        if (linked == true) _load();
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool outlined;
  const _ActionButton({required this.label, this.onTap, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : ZyraColors.accentBg,
          border: Border.all(color: ZyraColors.accentBorder, width: 1),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: onTap,
            child: Center(child: Text(label, style: ZyraText.button())),
          ),
        ),
      ),
    );
  }
}
