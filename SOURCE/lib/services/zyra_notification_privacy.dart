/// Local presentation rule for future push delivery. LOCK 40 does not send
/// notifications; the push adapter must call this before showing text.
String zyraMessageNotificationText(
  String messageText, {
  required bool hideMessageText,
}) => hideMessageText ? 'New message' : messageText;
