// Guardian notification settings use the same persisted five-category
// service and the same honest device-permission state as Seeker settings.
// Copy adapts by role; storage codes and consent semantics do not fork.

import 'package:flutter/material.dart';

import '../../services/zyra_notification_prefs_service.dart';
import '../../services/zyra_promotion_engine.dart';
import '../settings/notification_settings_screen.dart';

class WaliNotificationSettingsScreen extends StatelessWidget {
  final Future<Map<ZyraNotifyCategory, bool>?> Function()? loadPreferences;
  final Future<bool> Function(ZyraNotifyCategory, bool)? savePreference;

  const WaliNotificationSettingsScreen({
    super.key,
    this.loadPreferences,
    this.savePreference,
  });

  @override
  Widget build(BuildContext context) => NotificationSettingsScreen(
    role: ZyraPromotionRole.guardian,
    loadPreferences: loadPreferences,
    savePreference: savePreference,
  );
}
