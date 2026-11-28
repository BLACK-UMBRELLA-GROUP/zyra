import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_tap_feedback.dart';

/// LOCK 40 presentation. The owner supplies sample people and device state;
/// this widget cannot read a member account or sign out a real device.
enum ZyraPrivacySecurityPage { hiddenBlocked, appLock, signIn }

final class ZyraPrivacyPerson {
  const ZyraPrivacyPerson({
    required this.id,
    required this.firstName,
    required this.date,
  });

  final String id;
  final String firstName;
  final String date;
}

class ZyraPrivacySecurityPreview extends StatefulWidget {
  const ZyraPrivacySecurityPreview({
    super.key,
    required this.page,
    this.blocked = const [],
    this.hidden = const [],
    this.onUnblock,
    this.onShowAgain,
    this.lockEnabled = false,
    this.lockDelay = 'one_minute',
    this.switcherCover = true,
    this.hideMessageText = true,
    this.onLockChanged,
    this.onDelayChanged,
    this.onSwitcherCoverChanged,
    this.onMessageTextChanged,
    this.signedInWith = 'Apple',
    this.email = 'adam@…',
    this.backupSignInAdded = false,
    this.onAddBackupSignIn,
    this.otherDevicesPresent = true,
    this.onSignOutOtherDevices,
  });

  final ZyraPrivacySecurityPage page;
  final List<ZyraPrivacyPerson> blocked, hidden;
  final ValueChanged<String>? onUnblock, onShowAgain;
  final bool lockEnabled, switcherCover, hideMessageText;
  final String lockDelay;
  final Future<bool> Function(bool)? onLockChanged;
  final ValueChanged<String>? onDelayChanged;
  final ValueChanged<bool>? onSwitcherCoverChanged, onMessageTextChanged;
  final String signedInWith, email;
  final bool backupSignInAdded;
  final VoidCallback? onAddBackupSignIn;
  final bool otherDevicesPresent;
  final VoidCallback? onSignOutOtherDevices;

  @override
  State<ZyraPrivacySecurityPreview> createState() =>
      _ZyraPrivacySecurityPreviewState();
}

class _ZyraPrivacySecurityPreviewState
    extends State<ZyraPrivacySecurityPreview> {
  bool _busy = false;
  static const _activeGreen = Color(0xFF326B4C);

  @override
  Widget build(BuildContext context) {
    final page = widget.page;
    final title = switch (page) {
      ZyraPrivacySecurityPage.hiddenBlocked => 'Hidden and blocked',
      ZyraPrivacySecurityPage.appLock => 'App lock',
      ZyraPrivacySecurityPage.signIn => 'Sign-in & security',
    };
    return Material(
      key: ValueKey('privacy_security_${page.name}'),
      color: ZyraColors.ivoryTop,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: ZyraText.pageTitle()),
              const SizedBox(height: 50),
              Expanded(
                child: ListView(
                  key: const ValueKey('concept_account_action_scroll'),
                  physics: const ScrollPhysics(),
                  children: switch (page) {
                    ZyraPrivacySecurityPage.hiddenBlocked => _hiddenBlocked(),
                    ZyraPrivacySecurityPage.appLock => _appLock(),
                    ZyraPrivacySecurityPage.signIn => _signIn(),
                  },
                ),
              ),
              if (page == ZyraPrivacySecurityPage.signIn) ...[
                const SizedBox(height: 8),
                _signOutFooter(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _hiddenBlocked() => [
    _section('BLOCKED'),
    if (widget.blocked.isEmpty)
      _card([_empty('No one is blocked.')])
    else
      _card([
        for (final person in widget.blocked) _personRow(person, blocked: true),
      ]),
    const SizedBox(height: 8),
    _copy(
      "Blocked people can’t see you or contact you, and you won’t see them.",
      size: 12,
    ),
    const SizedBox(height: 36),
    _section('HIDDEN'),
    if (widget.hidden.isEmpty)
      _card([_empty('No one is hidden.')])
    else
      _card([
        for (final person in widget.hidden) _personRow(person, blocked: false),
      ]),
    const SizedBox(height: 8),
    _copy(
      "Hidden people don’t appear in your Profiles. They aren’t told.",
      size: 12,
    ),
  ];

  Widget _personRow(
    ZyraPrivacyPerson person, {
    required bool blocked,
  }) => Padding(
    key: ValueKey('privacy_person_${person.id}'),
    padding: const EdgeInsets.fromLTRB(16, 9, 16, 9),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(person.firstName, style: ZyraText.body(size: 15)),
              const SizedBox(height: 4),
              Text(
                '${blocked ? 'Blocked' : 'Hidden'} ${person.date}',
                style: ZyraText.body(size: 12, color: ZyraColors.secondaryText),
              ),
            ],
          ),
        ),
        OutlinedButton(
          key: ValueKey('privacy_${blocked ? 'unblock' : 'show'}_${person.id}'),
          onPressed: ZyraTapFeedback.onTap(
            context,
            blocked
                ? () => _confirmUnblock(person)
                : () => widget.onShowAgain?.call(person.id),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: ZyraColors.goldText,
            minimumSize: const Size(0, 34),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: BorderSide(color: ZyraColors.journeyGold),
            shape: const StadiumBorder(),
          ),
          child: Text(blocked ? 'Unblock' : 'Show again'),
        ),
      ],
    ),
  );

  Future<void> _confirmUnblock(ZyraPrivacyPerson person) async {
    if (widget.onUnblock == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ZyraColors.ivoryTop,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ZyraColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 55,
                height: 55,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ZyraColors.goldTextStrong),
                ),
                child: Text(
                  person.firstName[0],
                  style: ZyraText.heading(
                    size: 27,
                    color: ZyraColors.goldTextStrong,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Unblock ${person.firstName}?', style: ZyraText.pageTitle()),
              const SizedBox(height: 12),
              Text(
                "${person.firstName} won’t be told. An ended Journey or an old request does not come back.",
                textAlign: TextAlign.center,
                style: ZyraText.body(size: 14, color: ZyraColors.secondaryText),
              ),
              const SizedBox(height: 20),
              Divider(color: ZyraColors.divider),
              TextButton(
                key: const ValueKey('privacy_confirm_unblock'),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  widget.onUnblock?.call(person.id);
                },
                child: const Text('Unblock'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const ValueKey('privacy_keep_blocked'),
                onPressed: () => Navigator.of(sheetContext).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: ZyraColors.secondaryText,
                  side: BorderSide(color: ZyraColors.surfaceBorder),
                  shape: const StadiumBorder(),
                ),
                child: const Text('Keep blocked'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _appLock() => [
    _section('LOCK'),
    _card([
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lock ZYRA with Face ID',
                    style: ZyraText.body(size: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "If Face ID doesn’t work, use your phone’s passcode.",
                    style: ZyraText.body(
                      size: 12,
                      color: ZyraColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            if (_busy)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              CupertinoSwitch(
                key: const ValueKey('privacy_app_lock_switch'),
                value: widget.lockEnabled,
                onChanged: widget.onLockChanged == null ? null : _toggleLock,
                activeTrackColor: ZyraColors.goldTextFill,
                inactiveTrackColor: const Color(0xFFD8D3CB),
                thumbColor: ZyraColors.ivoryTop,
              ),
          ],
        ),
      ),
    ]),
    if (widget.lockEnabled) ...[
      const SizedBox(height: 34),
      _section('LOCK AFTER LEAVING ZYRA'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _delay('straight_away', 'Straight away'),
          _delay('one_minute', '1 minute'),
          _delay('fifteen_minutes', '15 minutes'),
          _delay('one_hour', '1 hour'),
        ],
      ),
    ],
    const SizedBox(height: 36),
    _section('PRIVACY ON THIS PHONE'),
    _card([
      _switchRow(
        'Hide ZYRA in the app switcher',
        'Shows a plain ZYRA screen instead of your last page.',
        widget.switcherCover,
        widget.onSwitcherCoverChanged,
        const ValueKey('privacy_switcher_cover'),
      ),
      _switchRow(
        'Hide message text in notifications',
        'Shows “New message” without the words.',
        widget.hideMessageText,
        widget.onMessageTextChanged,
        const ValueKey('privacy_hide_message_text'),
      ),
    ]),
    const SizedBox(height: 8),
    _copy(
      'These settings are for this phone only. Face ID stays on your phone; ZYRA never sees it.',
    ),
  ];

  Future<void> _toggleLock(bool value) async {
    if (_busy || widget.onLockChanged == null) return;
    setState(() => _busy = true);
    await widget.onLockChanged!(value);
    if (mounted) setState(() => _busy = false);
  }

  Widget _delay(String value, String label) => OutlinedButton(
    key: ValueKey('privacy_lock_delay_$value'),
    onPressed: ZyraTapFeedback.onTap(
      context,
      () => widget.onDelayChanged?.call(value),
    ),
    style: OutlinedButton.styleFrom(
      foregroundColor: value == widget.lockDelay
          ? ZyraColors.goldTextStrong
          : ZyraColors.espresso,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      minimumSize: const Size(0, 34),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(
        color: value == widget.lockDelay
            ? ZyraColors.goldTextStrong
            : ZyraColors.surfaceBorder,
      ),
      shape: const StadiumBorder(),
    ),
    child: Text(label, style: ZyraText.body(size: 13)),
  );

  Widget _switchRow(
    String title,
    String detail,
    bool value,
    ValueChanged<bool>? onChanged,
    Key key,
  ) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ZyraText.body(size: 15)),
              const SizedBox(height: 3),
              Text(
                detail,
                style: ZyraText.body(size: 12, color: ZyraColors.secondaryText),
              ),
            ],
          ),
        ),
        CupertinoSwitch(
          key: key,
          value: value,
          onChanged: onChanged,
          activeTrackColor: ZyraColors.goldTextFill,
          inactiveTrackColor: const Color(0xFFD8D3CB),
          thumbColor: ZyraColors.ivoryTop,
        ),
      ],
    ),
  );

  List<Widget> _signIn() => [
    _section('SIGN-IN'),
    _card([
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Signed in with ${widget.signedInWith}',
                style: ZyraText.body(size: 15),
              ),
            ),
            Text(
              widget.email,
              style: ZyraText.body(size: 13, color: ZyraColors.secondaryText),
            ),
          ],
        ),
      ),
    ]),
    const SizedBox(height: 8),
    _copy(
      'Your $_primaryAccount protects your account, including its own '
      'two-step check.',
    ),
    if (widget.onAddBackupSignIn != null || widget.backupSignInAdded) ...[
      const SizedBox(height: 31),
      _section('BACKUP SIGN-IN'),
      _card([_backupSignInRow()]),
      const SizedBox(height: 8),
      _copy(
        'If you ever lose your $_primaryAccount, you can still sign in '
        'with $_backupProvider.',
        size: 12.5,
      ),
    ],
    const SizedBox(height: 31),
    _section('SIGNED-IN DEVICES'),
    _card([
      _device('iPhone 15', 'This phone · active now', current: true),
      if (widget.otherDevicesPresent) ...[
        _device('iPad', 'Last active 18 Nov'),
        _device('iPhone 12', 'Last active 2 Nov'),
      ],
    ]),
    const SizedBox(height: 15),
    _copy(
      'Lost a phone? Sign out everywhere else, then change your '
      '$_primaryAccount password.',
    ),
  ];

  String get _primaryAccount =>
      widget.signedInWith == 'Google' ? 'Google account' : 'Apple ID';

  String get _backupProvider =>
      widget.signedInWith == 'Google' ? 'Apple' : 'Google';

  Widget _backupSignInRow() {
    final added = widget.backupSignInAdded;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              added ? _backupProvider : 'Add $_backupProvider as a backup',
              style: ZyraText.body(size: 15),
            ),
          ),
          const SizedBox(width: 8),
          if (added)
            Text('Added', style: ZyraText.body(size: 13, color: _activeGreen))
          else
            const Icon(
              Icons.chevron_right,
              color: ZyraColors.secondaryText,
              size: 18,
            ),
        ],
      ),
    );
    if (added) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('privacy_add_backup_sign_in'),
        borderRadius: BorderRadius.circular(16),
        onTap: ZyraTapFeedback.onTap(context, widget.onAddBackupSignIn),
        child: row,
      ),
    );
  }

  Widget _device(String name, String detail, {bool current = false}) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: ZyraText.body(size: 15)),
        const SizedBox(height: 4),
        Text(
          detail,
          style: ZyraText.body(
            size: 12,
            color: current ? _activeGreen : ZyraColors.secondaryText,
          ),
        ),
      ],
    ),
  );

  Widget _signOutFooter() => widget.otherDevicesPresent
      ? OutlinedButton(
          key: const ValueKey('privacy_sign_out_other_devices'),
          onPressed: ZyraTapFeedback.onTap(
            context,
            widget.onSignOutOtherDevices,
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: ZyraColors.dangerTextStrong,
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: ZyraColors.dangerTextStrong),
            shape: const StadiumBorder(),
          ),
          child: const Text('Sign out all other devices'),
        )
      : Center(
          child: Text(
            'Only this phone is signed in.',
            style: ZyraText.body(size: 14, color: _activeGreen),
          ),
        );

  Widget _section(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: ZyraText.chapterLabel(color: ZyraColors.secondaryText),
    ),
  );

  Widget _empty(String text) => Padding(
    padding: const EdgeInsets.all(16),
    child: Text(text, style: ZyraText.body(size: 14)),
  );

  Widget _copy(String text, {double size = 13}) => Text(
    text,
    style: ZyraText.body(size: size, color: ZyraColors.secondaryText),
  );

  Widget _card(List<Widget> children) => DecoratedBox(
    decoration: BoxDecoration(
      color: ZyraColors.cardSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: ZyraColors.surfaceBorder),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10000000),
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[children[i]],
      ],
    ),
  );
}
