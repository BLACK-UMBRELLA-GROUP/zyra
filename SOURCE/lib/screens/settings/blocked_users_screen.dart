// Blocked Users — Settings.
//
// Founder approved 2026-08-03: "Blocked users should not appear anywhere
// within the Connections page. Instead: Settings → Blocked Users. This
// keeps Connections dedicated solely to Journey management while Settings
// remains responsible for account and privacy controls."
//
// Blocked users were already absent from Connections — `profile_blocks`
// hides them both ways through RLS, and no section ever listed them. What
// was missing was anywhere to SEE them. Blocking was one-way: you could
// block from Browse or a Connections card and had no route back. Unblock
// existed in the service and had no caller.
//
// So this is not a move. It is the other half of a feature that shipped
// with only its first half.
//
// Structure copied from HelpSupportScreen: transparent AppBar over the
// gender gradient, body extended behind it, back arrow. Same as every
// other pushed settings screen.

import 'package:flutter/material.dart';

import '../../models/seeker_profile.dart';
import '../../services/zyra_discovery_service.dart';
import '../../services/zyra_report_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_profile_image.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../../widgets/zyra_loading.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  bool _loading = true;
  List<SeekerProfile> _blocked = [];
  final Set<String> _working = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ids = await ZyraReportService.blockedIds();
    final profiles = await ZyraDiscoveryService.profilesByIds(ids);
    if (!mounted) return;
    setState(() {
      _blocked = profiles;
      _loading = false;
    });
  }

  Future<void> _unblock(SeekerProfile p) async {
    setState(() => _working.add(p.id));
    final ok = await ZyraReportService.unblock(p.id);
    if (!mounted) return;
    setState(() {
      _working.remove(p.id);
      if (ok) _blocked.removeWhere((x) => x.id == p.id);
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("That didn't go through. Please try again.")),
      );
    }
  }

  /// Confirmed, not instant. Unblocking makes you visible to each other
  /// again — the opposite of a safety action, and not something to do by
  /// mis-tap on a list.
  void _confirmUnblock(SeekerProfile p) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ZyraColors.luxuryDarkPurple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Unblock ${p.firstName}?', style: ZyraText.heading(size: 16)),
        content: Text(
          'You will be able to see each other in ZYRA again. Any report you '
          'made stays with us — unblocking does not withdraw it.',
          style: ZyraText.subtext(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: ZyraText.subtext(size: 13)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _unblock(p);
            },
            child: Text('Unblock', style: ZyraText.button(size: 13)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Blocked Users', style: ZyraText.heading(size: 17)),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: ZyraColors.genderGradient(AppState.instance.gender)),
        child: _loading
            ? const ZyraLoading()
            : ListView(
                padding: EdgeInsets.fromLTRB(20, topInset + 8, 20, 40),
                children: [
                  if (_blocked.isEmpty)
                    const ZyraEmptyState(
                      icon: Icons.block,
                      message: "You haven't blocked anyone. If you do, they'll "
                          'appear here and you can unblock them at any time.',
                    )
                  else ...[
                    Text(
                      'Blocking works both ways — you and they are invisible '
                      'to each other everywhere in ZYRA.',
                      style: ZyraText.subtext(size: 12.5),
                    ),
                    const SizedBox(height: 16),
                    ..._blocked.map((p) => _BlockedRow(
                          profile: p,
                          busy: _working.contains(p.id),
                          onUnblock: () => _confirmUnblock(p),
                        )),
                  ],
                ],
              ),
      ),
    );
  }
}

class _BlockedRow extends StatelessWidget {
  final SeekerProfile profile;
  final bool busy;
  final VoidCallback onUnblock;

  const _BlockedRow({required this.profile, required this.busy, required this.onUnblock});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ZyraColors.iconButtonBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ZyraColors.iconButtonBorder, width: 0.5),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ZyraProfileImage(profile.photoUrl, width: 44, height: 44),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                '${profile.firstName}, ${profile.age}',
                style: ZyraText.body(size: 14, color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: busy ? null : onUnblock,
              child: Text(
                busy ? 'Unblocking…' : 'Unblock',
                style: ZyraText.button(
                  size: 12.5,
                  color: Colors.white.withValues(alpha: busy ? 0.4 : 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
