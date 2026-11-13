class ZyraKnownPersonCodePreview {
  final String firstName;
  final int age;
  final String city;

  const ZyraKnownPersonCodePreview({
    required this.firstName,
    required this.age,
    required this.city,
  });

  static ZyraKnownPersonCodePreview? fromRow(Map<String, dynamic> row) {
    final firstName = row['owner_first_name'];
    final age = row['owner_age'];
    final city = row['owner_location'];
    if (firstName is! String ||
        firstName.trim().isEmpty ||
        age is! num ||
        city is! String ||
        city.trim().isEmpty) {
      return null;
    }
    return ZyraKnownPersonCodePreview(
      firstName: firstName.trim(),
      age: age.toInt(),
      city: city.trim(),
    );
  }
}

class ZyraKnownPersonCodeLookup {
  final bool serverAvailable;
  final bool rateLimited;
  final ZyraKnownPersonCodePreview? person;

  const ZyraKnownPersonCodeLookup.available(this.person)
    : serverAvailable = true,
      rateLimited = false;

  const ZyraKnownPersonCodeLookup.unavailable()
    : serverAvailable = false,
      rateLimited = false,
      person = null;

  const ZyraKnownPersonCodeLookup.rateLimited()
    : serverAvailable = false,
      rateLimited = true,
      person = null;
}

enum ZyraKnownPersonConsiderOutcome {
  considered,
  matched,
  noLongerAvailable,
  rateLimited,
  failed,
}
