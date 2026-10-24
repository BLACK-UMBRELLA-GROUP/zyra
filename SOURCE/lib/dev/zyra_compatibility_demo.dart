/// Display fixtures, not a compatibility algorithm or server response.
/// Used only by an authorized, non-persisted sample profile route.
abstract final class ZyraCompatibilityDemo {
  static const categories = <ZyraCompatibilityDemoCategory>[
    ZyraCompatibilityDemoCategory('Lifestyle', 80, 15, 5),
    ZyraCompatibilityDemoCategory('Work & Education', 70, 20, 10),
    ZyraCompatibilityDemoCategory('Family Values', 85, 10, 5),
    ZyraCompatibilityDemoCategory('Marriage Goals', 90, 5, 5),
    ZyraCompatibilityDemoCategory('Personality', 60, 30, 10),
    ZyraCompatibilityDemoCategory('Deen', 65, 25, 10),
  ];
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
