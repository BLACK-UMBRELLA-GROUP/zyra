// The historical class/route name remains compatible with callers. This is
// membership information, not a checkout and never an entitlement mutation.
// Original comparison/mock purchase preserved outside SOURCE, 2026-09-13.
import 'package:flutter/material.dart';
import '../../data/zyra_membership_catalog.dart';
import '../../services/zyra_product_telemetry.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';

class UpgradeScreen extends StatefulWidget {
  final ZyraTelemetrySurface telemetrySurface;

  const UpgradeScreen({
    super.key,
    this.telemetrySurface = ZyraTelemetrySurface.seeker,
  });

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  @override
  void initState() {
    super.initState();
    ZyraProductTelemetry.instance.record(
      feature: ZyraTelemetryFeature.membership,
      name: ZyraTelemetryEventName.opened,
      action: ZyraTelemetryAction.pageView,
      surface: widget.telemetrySurface,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: BoxDecoration(
        gradient: ZyraColors.genderGradient(AppState.instance.gender),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.arrow_back, color: ZyraColors.ink(0.70)),
                  ),
                  Expanded(
                    child: Text(
                      'Membership',
                      style: ZyraText.heading(size: 18),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                children: [
                  Text('ZYRA One', style: ZyraText.wordmark(size: 26)),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how you take part in the marriage Journey.',
                    style: ZyraText.subtext(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    ZyraMembershipCatalog.availability,
                    style: ZyraText.subtext(size: 12.5),
                  ),
                  const SizedBox(height: 20),
                  _MembershipCard(
                    product: ZyraMembershipProduct.seekerOne,
                    features: const [
                      'The complete premium Seeker experience',
                      'Discover matches and progress through your marriage Journey',
                      'Deeper activity and Journey insights',
                    ],
                  ),
                  const SizedBox(height: 14),
                  _MembershipCard(
                    product: ZyraMembershipProduct.seekerBasic,
                    features: const [
                      'One Active Journey at a time',
                      'Up to 50 active Considers (Likes) and 10 Saves',
                      'Up to 5 Considers (Likes) each day',
                      'Up to 25 profile swipes every 4 hours',
                      'An advert after every 5 swipes',
                      'Now is included; Insights requires ZYRA One',
                    ],
                  ),
                  const SizedBox(height: 14),
                  _MembershipCard(
                    product: ZyraMembershipProduct.guardianOne,
                    features: const [
                      'Eligible to view and comment across permitted Journeys',
                      'Eligible to enter permitted Journey conversations',
                      'Use Guardian Network to discover and recommend Seekers',
                    ],
                  ),
                  const SizedBox(height: 14),
                  _MembershipCard(
                    product: ZyraMembershipProduct.guardianBasic,
                    features: const [
                      'View the linked Seeker’s Journey',
                      'No Journey commenting or conversation entry',
                      'No Guardian Network page',
                      'Invitation, consent, reporting and safety controls remain available',
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ZyraMembershipCatalog.guardianAccessTerms,
                    style: ZyraText.subtext(size: 12.5),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Compatibility purchases',
                    style: ZyraText.heading(size: 17),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ZyraMembershipCatalog.compatibilityTerms,
                    style: ZyraText.subtext(size: 12.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ZyraMembershipCatalog.compatibilityPrices,
                    style: ZyraText.subtext(size: 12.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ZyraMembershipCatalog.compatibilityAvailability,
                    style: ZyraText.subtext(size: 12.5),
                  ),
                  const SizedBox(height: 20),
                  Text('Before joining', style: ZyraText.heading(size: 17)),
                  const SizedBox(height: 8),
                  Text(
                    ZyraMembershipCatalog.trialTerms,
                    style: ZyraText.subtext(size: 12.5),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Using both experiences does not make you your own Guardian. '
                    'Guardian permissions and romantic exclusions still apply. '
                    'A paid Guardian membership never transfers another '
                    'person’s identity, profile, history or Main Guardian authority.',
                    style: ZyraText.subtext(size: 12.5),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Blocking, reporting, privacy and account controls do not '
                    'require a subscription. Membership changes do not erase '
                    'Guardian links or Journey history.',
                    style: ZyraText.subtext(size: 12.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MembershipCard extends StatelessWidget {
  final ZyraMembershipProduct product;
  final List<String> features;

  const _MembershipCard({required this.product, required this.features});

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('membership-${product.name}'),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: ZyraColors.iconButtonBg,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: ZyraColors.iconButtonBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ZyraMembershipCatalog.title(product),
          style: ZyraText.heading(size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          ZyraMembershipCatalog.price(product),
          style: ZyraText.body(size: 16),
        ),
        const SizedBox(height: 12),
        for (final feature in features)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(feature, style: ZyraText.subtext(size: 12.5)),
          ),
        const SizedBox(height: 6),
        Text(
          'Not available to purchase yet',
          style: ZyraText.subtext(size: 12),
        ),
      ],
    ),
  );
}
