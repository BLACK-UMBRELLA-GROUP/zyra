/// LOCK 49. An in-memory family introduction between fictional profiles.
enum ZyraFamilyIntroductionPhase {
  needsApproval,
  awaitingReply,
  thinking,
  bothFamiliesOpen,
  choosingPlace,
  preparing,
  notApproved,
  notTakenUp,
  notTakenForward,
}

enum ZyraFamilyIntroductionReply {
  open('We’re open to this'),
  think('Let us think about it'),
  no('Not at this time');

  const ZyraFamilyIntroductionReply(this.label);

  final String label;
}

enum ZyraFamilyIntroductionSide { sender, receiver }

class ZyraFamilyIntroductionPreview {
  ZyraFamilyIntroductionPreview({
    required this.id,
    required this.senderSeekerId,
    required this.receiverSeekerId,
    required this.senderIsMain,
    required this.date,
  }) : _phase = senderIsMain
           ? ZyraFamilyIntroductionPhase.awaitingReply
           : ZyraFamilyIntroductionPhase.needsApproval;

  final String id, senderSeekerId, receiverSeekerId;
  final bool senderIsMain;
  final DateTime date;
  ZyraFamilyIntroductionPhase _phase;
  bool? _senderAnswer, _receiverAnswer;
  ZyraFamilyIntroductionReply? _reply;

  ZyraFamilyIntroductionPhase get phase => _phase;
  ZyraFamilyIntroductionReply? get reply => _reply;

  bool approve({required bool yes}) {
    if (_phase != ZyraFamilyIntroductionPhase.needsApproval) return false;
    _phase = yes
        ? ZyraFamilyIntroductionPhase.awaitingReply
        : ZyraFamilyIntroductionPhase.notApproved;
    return true;
  }

  bool answerFamily(ZyraFamilyIntroductionReply reply) {
    if (_phase != ZyraFamilyIntroductionPhase.awaitingReply &&
        (_phase != ZyraFamilyIntroductionPhase.thinking ||
            reply == ZyraFamilyIntroductionReply.think)) {
      return false;
    }
    _reply = reply;
    _phase = switch (reply) {
      ZyraFamilyIntroductionReply.open =>
        ZyraFamilyIntroductionPhase.bothFamiliesOpen,
      ZyraFamilyIntroductionReply.think => ZyraFamilyIntroductionPhase.thinking,
      ZyraFamilyIntroductionReply.no => ZyraFamilyIntroductionPhase.notTakenUp,
    };
    return true;
  }

  // Individual choices stay private. Each page checks only whether its own
  // answer was saved. Family status remains neutral until both answers exist.
  bool hasAnswered(ZyraFamilyIntroductionSide side) => switch (side) {
    ZyraFamilyIntroductionSide.sender => _senderAnswer != null,
    ZyraFamilyIntroductionSide.receiver => _receiverAnswer != null,
  };

  bool canChangeAnswer(ZyraFamilyIntroductionSide side) =>
      _phase == ZyraFamilyIntroductionPhase.bothFamiliesOpen &&
      hasAnswered(side) &&
      !hasAnswered(switch (side) {
        ZyraFamilyIntroductionSide.sender =>
          ZyraFamilyIntroductionSide.receiver,
        ZyraFamilyIntroductionSide.receiver =>
          ZyraFamilyIntroductionSide.sender,
      });

  bool changeAnswer(ZyraFamilyIntroductionSide side) {
    if (!canChangeAnswer(side)) return false;
    switch (side) {
      case ZyraFamilyIntroductionSide.sender:
        _senderAnswer = null;
      case ZyraFamilyIntroductionSide.receiver:
        _receiverAnswer = null;
    }
    return true;
  }

  bool answerSeeker(ZyraFamilyIntroductionSide side, {required bool yes}) {
    if (_phase != ZyraFamilyIntroductionPhase.bothFamiliesOpen ||
        hasAnswered(side)) {
      return false;
    }
    switch (side) {
      case ZyraFamilyIntroductionSide.sender:
        _senderAnswer = yes;
      case ZyraFamilyIntroductionSide.receiver:
        _receiverAnswer = yes;
    }
    if (_senderAnswer != null && _receiverAnswer != null) {
      _phase = _senderAnswer! && _receiverAnswer!
          ? ZyraFamilyIntroductionPhase.choosingPlace
          : ZyraFamilyIntroductionPhase.notTakenForward;
    }
    return true;
  }

  bool reservePlaces({required bool senderReady, required bool receiverReady}) {
    if (_phase != ZyraFamilyIntroductionPhase.choosingPlace ||
        !senderReady ||
        !receiverReady) {
      return false;
    }
    _phase = ZyraFamilyIntroductionPhase.preparing;
    return true;
  }

  bool letItGo() {
    if (_phase != ZyraFamilyIntroductionPhase.choosingPlace) return false;
    _phase = ZyraFamilyIntroductionPhase.notTakenForward;
    return true;
  }
}
