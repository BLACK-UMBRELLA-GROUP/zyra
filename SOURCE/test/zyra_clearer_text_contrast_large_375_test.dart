// OA-ZYRA-371 / Q197: the full screen audit is an explicit opt-in.
import 'package:flutter_test/flutter_test.dart';

import 'support/zyra_clearer_text_corpus.dart';

void main() {
  if (!const bool.fromEnvironment('ZYRA_FULL_TEXT_AUDIT')) {
    test(
      'full screen audit requires explicit opt-in',
      () {},
      skip: 'Use --dart-define=ZYRA_FULL_TEXT_AUDIT=true for the hosted audit.',
    );
    return;
  }
  runZyraTextContrastCorpus(zyraContrastLarge375);
}
