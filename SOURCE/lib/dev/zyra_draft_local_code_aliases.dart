/// Fictional presentation aliases for LOCK 9's twenty-character boxes.
/// These never enter the production parser or an RPC. Canonical sample
/// resolvers remain unchanged; each alias names one explicit existing fixture.
enum ZyraLocalCodeContext { scan, addGuardian, addSeeker }

abstract final class ZyraLocalCodeAliases {
  static const master = '7K2MQ9TD4HXA2B8C5E1F';
  static const scan = <String, String>{
    master: 'ZYRA-DRAFT-SARA',
    'DRAFTAMIRA0000000000': 'ZYRA-DRAFT-AMIRA',
    'DRAFTAISHA0000000000': 'ZYRA-DRAFT-AISHA',
    'DRAFTMARYAM000000000': 'ZYRA-DRAFT-MARYAM',
    'DRAFTHANA00000000001': 'ZYRA-DRAFT-HANA',
    'DRAFTNOOR00000000001': 'ZYRA-DRAFT-NOOR',
    'DRAFTZAINAB000000000': 'ZYRA-DRAFT-ZAINAB',
    'DRAFTSAFIYA000000000': 'ZYRA-DRAFT-SAFIYA',
  };
  static const guardian = <String, String>{
    master: 'ZYRA-DEMO-GUARDIAN-IBRAHIM',
  };
  static const seeker = <String, String>{master: 'ZYRA-DEMO-SEEKER-ADAM'};

  static Map<String, String> forContext(ZyraLocalCodeContext context) =>
      switch (context) {
        ZyraLocalCodeContext.scan => scan,
        ZyraLocalCodeContext.addGuardian => guardian,
        ZyraLocalCodeContext.addSeeker => seeker,
      };

  static String? canonical(ZyraLocalCodeContext context, String entry) =>
      forContext(context)[entry];

  /// Only whole, exact fictional fixtures are adapted. A URI, unknown suffix,
  /// or production code cannot be reduced to a known local identity.
  static String? entry(ZyraLocalCodeContext context, String raw) {
    final value = raw.trim().toUpperCase();
    for (final pair in forContext(context).entries) {
      final grouped = List.generate(
        5,
        (i) => pair.key.substring(i * 4, i * 4 + 4),
      ).join('-');
      if (value == pair.value ||
          value == pair.key ||
          value == 'ZYRA-$grouped') {
        return pair.key;
      }
    }
    return null;
  }
}
