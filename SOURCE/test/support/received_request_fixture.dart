import 'package:zyra/dev/zyra_view_request_draft_model.dart';

/// An explicit incoming sample for older tests that exercise request flows.
/// The app model starts empty and is also tested directly.
class ReceivedRequestFixture extends ViewRequestDraftModel {
  ReceivedRequestFixture({super.capacity, super.clock}) {
    seedReceived(draftProfiles.first.id);
  }

  @override
  void reset() {
    super.reset();
    seedReceived(draftProfiles.first.id);
  }

  @override
  bool seedJourneys(int count) {
    if (!super.seedJourneys(count)) return false;
    seedReceived(draftProfiles.first.id);
    return true;
  }
}
