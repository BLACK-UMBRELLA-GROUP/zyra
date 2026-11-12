/// Display fixtures, not a compatibility algorithm or server response.
/// Used only by an authorized, non-persisted sample profile route.
abstract final class ZyraCompatibilityDemo {
  static const topicNames = [
    'Lifestyle',
    'Work & Education',
    'Family Values',
    'Marriage Goals',
    'Personality',
    'Deen',
  ];

  static final categories = List<ZyraCompatibilityDemoCategory>.unmodifiable([
    ZyraCompatibilityDemoCategory(topicNames[0], 80, 15, 5),
    ZyraCompatibilityDemoCategory(topicNames[1], 70, 20, 10),
    ZyraCompatibilityDemoCategory(topicNames[2], 85, 10, 5),
    ZyraCompatibilityDemoCategory(topicNames[3], 90, 5, 5),
    ZyraCompatibilityDemoCategory(topicNames[4], 60, 30, 10),
    ZyraCompatibilityDemoCategory(topicNames[5], 65, 25, 10),
  ]);
}

class ZyraCompatibilityDemoCategory {
  final String name;
  final int aligned;
  final int discuss;
  final int opposed;

  const ZyraCompatibilityDemoCategory(
    this.name,
    this.aligned,
    this.discuss,
    this.opposed,
  ) : assert(aligned + discuss + opposed == 100),
      assert(aligned >= 0 && discuss >= 0 && opposed >= 0);
}
