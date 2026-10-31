import 'dart:async';

import 'package:flutter/material.dart';
import '../../dev/zyra_app_gold_preview.dart';

import '../../services/zyra_report_service.dart';
import '../../services/zyra_account_state.dart';
import '../../services/zyra_auth.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_loading.dart';
import '../../widgets/zyra_state_widgets.dart';

class SafetyCaseStatusScreen extends StatefulWidget {
  final Future<List<ZyraSafetyCase>?> Function()? loadCases;

  const SafetyCaseStatusScreen({super.key, this.loadCases});

  @override
  State<SafetyCaseStatusScreen> createState() => _SafetyCaseStatusScreenState();
}

class _SafetyCaseStatusScreenState extends State<SafetyCaseStatusScreen> {
  late final String? _owner;
  late final int _generation;
  StreamSubscription<dynamic>? _authSubscription;
  bool _revoked = false;
  int _request = 0;
  bool _loading = true;
  bool _failed = false;
  List<ZyraSafetyCase> _cases = const [];

  @override
  void initState() {
    super.initState();
    _owner = _currentUser();
    _generation = ZyraAccountState.generation;
    AppState.instance.addListener(_ownerChanged);
    try {
      _authSubscription = ZyraAuth.authStateChanges.listen(
        (event) {
          if (event.session?.user.id != _owner) _revoked = true;
          _ownerChanged();
        },
        onError: (Object _, StackTrace _) {
          _revoked = true;
          _ownerChanged();
        },
      );
    } catch (_) {
      // Injected no-client previews retain the same generation boundary.
    }
    _load();
  }

  String? _currentUser() {
    try {
      return ZyraAuth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  bool get _current {
    if (_currentUser() != _owner ||
        ZyraAccountState.generation != _generation ||
        ZyraAccountState.isSigningOut) {
      _revoked = true;
    }
    return mounted && !_revoked;
  }

  void _ownerChanged() {
    if (!mounted || _current) return;
    setState(() {
      _cases = const [];
      _request++;
    });
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_ownerChanged);
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!_current) return;
    final request = ++_request;
    setState(() => _loading = true);
    List<ZyraSafetyCase>? result;
    try {
      result =
          await (widget.loadCases?.call() ?? ZyraReportService.safetyCases());
    } catch (_) {
      result = null;
    }
    if (!_current || request != _request) return;
    setState(() {
      _loading = false;
      _failed = result == null;
      _cases = result ?? const [];
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Your safety reports', style: ZyraText.heading(size: 17)),
    ),
    body: Container(
      decoration: ZyraAppGoldDecoration(
        gradient: ZyraColors.genderGradient(AppState.instance.gender),
      ),
      child: SafeArea(
        top: false,
        child: !_current
            ? const SizedBox.shrink()
            : _loading
            ? const ZyraLoading(label: 'Checking your reports…')
            : _failed
            ? ZyraUnknownErrorState(onRetry: _load)
            : _cases.isEmpty
            ? const _NoSafetyCases()
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
                children: [
                  const _SafetyReportExplanation(),
                  const SizedBox(height: 18),
                  ...List.generate(
                    _cases.length,
                    (index) => Padding(
                      padding: EdgeInsets.only(
                        bottom: index == _cases.length - 1 ? 0 : 10,
                      ),
                      child: _SafetyCaseCard(value: _cases[index]),
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}

class _NoSafetyCases extends StatelessWidget {
  const _NoSafetyCases();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
    children: const [
      _SafetyReportExplanation(),
      SizedBox(height: 90),
      ZyraEmptyState(
        icon: Icons.verified_user_outlined,
        title: 'No reports submitted',
        message:
            'If you report a member or a Guardian Circle message, its review status will appear here.',
      ),
    ],
  );
}

class _SafetyReportExplanation extends StatelessWidget {
  const _SafetyReportExplanation();

  @override
  Widget build(BuildContext context) => Text(
    'Track safety reports you have sent to ZYRA. You will see when each '
    'report is received, under review or complete.',
    style: ZyraText.subtext(size: 12.5, color: ZyraColors.ink(0.54)),
  );
}

class _SafetyCaseCard extends StatelessWidget {
  final ZyraSafetyCase value;

  const _SafetyCaseCard({required this.value});

  String _date(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: ZyraColors.surfaceFill,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: ZyraColors.surfaceBorder),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.shield_outlined, color: ZyraColors.journeyGold, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value.typeLabel, style: ZyraText.body(size: 14.5)),
              const SizedBox(height: 5),
              Text(
                value.statusLabel,
                style: ZyraText.body(size: 12.5, color: ZyraColors.goldText),
              ),
              const SizedBox(height: 4),
              Text(
                'Submitted ${_date(value.createdAt)}',
                style: ZyraText.subtext(size: 11.5),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
