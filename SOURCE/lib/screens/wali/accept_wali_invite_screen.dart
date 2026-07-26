// Shared invite-code entry screen — reachable from LinkWaliScreen on
// both sides (a Seeker linking a Wali, or a Wali linking a Seeker).
// Previews who sent the code before committing (via preview_wali_
// invite), then commits via accept_wali_invite. Same screen serves
// both directions since the underlying mechanism is symmetric — see
// ZyraWaliLinkService's doc comment.

import 'package:flutter/material.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';

class AcceptWaliInviteScreen extends StatefulWidget {
  const AcceptWaliInviteScreen({super.key});

  @override
  State<AcceptWaliInviteScreen> createState() => _AcceptWaliInviteScreenState();
}

class _AcceptWaliInviteScreenState extends State<AcceptWaliInviteScreen> {
  final _controller = TextEditingController();
  bool _checking = false;
  bool _accepting = false;
  String? _error;
  Map<String, String>? _preview;

  Future<void> _checkCode() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _checking = true;
      _error = null;
      _preview = null;
    });
    final preview = await ZyraWaliLinkService.previewInvite(code);
    if (!mounted) return;
    setState(() {
      _checking = false;
      if (preview == null) {
        _error = "That code wasn't found. Check it and try again.";
      } else if (preview['status'] == 'expired') {
        _error = 'This code has expired — ask them to generate a new one.';
      } else if (preview['status'] != 'pending') {
        _error = 'That code has already been used.';
      } else {
        _preview = preview;
      }
    });
  }

  Future<void> _accept() async {
    setState(() {
      _accepting = true;
      _error = null;
    });
    final error = await ZyraWaliLinkService.acceptInvite(_controller.text.trim());
    if (!mounted) return;
    setState(() => _accepting = false);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Enter Invite Code', style: ZyraText.heading(size: 17)),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: Container(
        // 2026-07-25: gender-matched gradient (DR-ZYRA-094). This screen
        // is only ever reached by an already-signed-in account (Seeker
        // or Wali) linking the other party, so gender is always known
        // here — see ZyraColors.genderGradient() doc comment.
        decoration: BoxDecoration(gradient: ZyraColors.genderGradient(AppState.instance.gender)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text("Enter the code they shared with you.", style: ZyraText.subtext()),
                const SizedBox(height: 20),
                TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  style: ZyraText.heading(size: 20).copyWith(letterSpacing: 4),
                  decoration: InputDecoration(
                    hintText: 'ABCD1234',
                    hintStyle: ZyraText.subtext(size: 20),
                    filled: true,
                    fillColor: ZyraColors.iconButtonBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                  onChanged: (_) => setState(() {
                    _preview = null;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 16),
                if (_preview != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ZyraColors.iconButtonBg,
                      border: Border.all(color: ZyraColors.iconButtonBorder, width: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_preview!['inviterFirstName']} has invited you to link as their '
                      '${_preview!['inviterRole'] == 'seeker' ? 'Wali' : 'Seeker'}.',
                      style: ZyraText.body(size: 13, color: Colors.white),
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  ZyraErrorBanner(message: _error!, onDismiss: () => setState(() => _error = null)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
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
                        onTap: _checking || _accepting ? null : (_preview == null ? _checkCode : _accept),
                        child: Center(
                          child: Text(
                            _checking
                                ? 'Checking…'
                                : _accepting
                                    ? 'Linking…'
                                    : (_preview == null ? 'Check Code' : 'Confirm Link'),
                            style: ZyraText.button(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
