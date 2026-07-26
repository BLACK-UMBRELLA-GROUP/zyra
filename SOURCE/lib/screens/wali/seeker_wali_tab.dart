// Seeker's "Wali" bottom-nav tab — per APP/Navigation/SEEKER
// NAVIGATION/Summary.md's ratified 4-tab structure (Browse /
// Connections / Wali / Profile). Added 2026-07-26 (DR-ZYRA-101 audit,
// nav bar fix): the live nav previously had no dedicated Wali tab at
// all, only a "Link a Wali" row buried in Profile's Settings section.
//
// Deliberately a thin wrapper around LinkWaliScreen's existing body —
// that screen already does everything a Seeker needs here (show
// linked Wali(s), generate an invite, or enter a code) and is reused
// as-is for the Wali's own equivalent flow (asWali: true). This tab
// just drops the Scaffold/AppBar-with-back-button chrome that made
// sense for a screen reached by pushing a route, and instead renders
// as a tab body (gradient background + SafeArea) matching Browse/
// Connections/Profile's own tab styling.

import 'package:flutter/material.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
import 'accept_wali_invite_screen.dart';

class SeekerWaliTab extends StatefulWidget {
  const SeekerWaliTab({super.key});

  @override
  State<SeekerWaliTab> createState() => _SeekerWaliTabState();
}

class _SeekerWaliTabState extends State<SeekerWaliTab> {
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
    final linked = await ZyraWaliLinkService.fetchLinkedPeople(asWali: false);
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
    return Container(
      decoration: BoxDecoration(gradient: ZyraColors.genderGradient(AppState.instance.gender)),
      child: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white54))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                children: [
                  Text('Wali', style: ZyraText.heading(size: 22)),
                  const SizedBox(height: 20),
                  if (_linked.isEmpty)
                    ZyraEmptyState(
                      icon: Icons.link,
                      message: "No Wali linked yet. Invite one, or enter a code they've sent you.",
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
                  Text('INVITE A WALI', style: ZyraText.chapterLabel(color: Colors.white54)),
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
                          Text('Share this code with your Wali:', style: ZyraText.subtext(size: 12)),
                          const SizedBox(height: 8),
                          Text(_generatedCode!, style: ZyraText.heading(size: 22).copyWith(letterSpacing: 4)),
                          const SizedBox(height: 8),
                          Text(
                            "Sharing (SMS, email, WhatsApp) isn't wired up yet in this preview build — copy and send this code however works today.",
                            style: ZyraText.subtext(size: 11, color: Colors.white38),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This code expires 7 days from now.',
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
