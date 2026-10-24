/// Signup intent only. None of these values proves payment, identity or access.
enum ZyraSignupRole { seeker, guardian }

enum ZyraSignupMembershipKind { basic, one, family }

class ZyraSignupMembershipChoice {
  final ZyraSignupMembershipKind kind;
  final int seekers;
  final int guardians;

  const ZyraSignupMembershipChoice({
    required this.kind,
    this.seekers = 0,
    this.guardians = 0,
  });

  bool isValidFor(ZyraSignupRole role) {
    if (kind != ZyraSignupMembershipKind.family) {
      return seekers == 0 && guardians == 0;
    }
    if (seekers < 0 || seekers > 10 || guardians < 0 || guardians > 10) {
      return false;
    }
    return role == ZyraSignupRole.seeker ? seekers > 0 : guardians > 0;
  }

  Map<String, Object> toJson() => {
    'kind': kind.name,
    'seekers': seekers,
    'guardians': guardians,
  };

  static ZyraSignupMembershipChoice fromJson(
    Object? value, {
    required ZyraSignupRole role,
  }) {
    if (value is! Map<String, dynamic> ||
        value.length != 3 ||
        !ZyraSignupMembershipKind.values.any(
          (kind) => kind.name == value['kind'],
        ) ||
        value['seekers'] is! int ||
        value['guardians'] is! int) {
      throw const FormatException('Invalid membership choice.');
    }
    final choice = ZyraSignupMembershipChoice(
      kind: ZyraSignupMembershipKind.values.byName(value['kind']),
      seekers: value['seekers'],
      guardians: value['guardians'],
    );
    if (!choice.isValidFor(role)) {
      throw const FormatException('Invalid membership choice.');
    }
    return choice;
  }
}

/// Retained separately from the erased identity form. This is not entitlement.
class ZyraSignupMembershipIntent {
  final ZyraSignupRole role;
  final ZyraSignupMembershipChoice choice;

  const ZyraSignupMembershipIntent({required this.role, required this.choice});

  bool get isValid => choice.isValidFor(role);

  Map<String, Object> toJson() => {
    'version': 1,
    'role': role.name,
    'choice': choice.toJson(),
  };

  static ZyraSignupMembershipIntent fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value.length != 3 ||
        value['version'] != 1 ||
        !ZyraSignupRole.values.any((role) => role.name == value['role'])) {
      throw const FormatException('Invalid membership intent.');
    }
    final role = ZyraSignupRole.values.byName(value['role']);
    return ZyraSignupMembershipIntent(
      role: role,
      choice: ZyraSignupMembershipChoice.fromJson(value['choice'], role: role),
    );
  }
}
