// Delivers one explicit, offline Circle arrival to the admitted Seeker.
import 'package:zyra/services/zyra_family_messaging_service.dart';

class VisualCircleArrivalFixture {
  static const messageId = 'lock15-lock17-lock18-delivered';
  static const readKey =
      'draft-self:draft-self:$messageId:draft-guardian-hassan';
  static const focusToken = 'circle:$readKey';
  final _messages = <ZyraFamilyMessage>[];

  List<ZyraFamilyMessage> forScope(String seeker, String viewer) =>
      seeker == 'draft-self' && viewer == 'draft-self' ? _messages : const [];

  void deliver() {
    _messages.add(
      ZyraFamilyMessage(
        id: messageId,
        senderId: 'draft-guardian-hassan',
        senderFirstName: 'Hassan',
        body: 'A newly delivered message for this Circle test.',
        createdAt: DateTime.utc(2026, 10, 12, 0, 13),
        unreadForMe: true,
      ),
    );
  }
}
