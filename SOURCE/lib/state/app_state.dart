// Shared in-memory app state — the founder's own profile fields
// (collected across Chapter 1/2 onboarding) plus Browse decisions
// (Declined/Saved/Outgoing Likes per PROFILE DECISION SYSTEM/Summary.md)
// and the resulting Potential/Active Journeys (MATCH_UX_SPEC_CURRENT_
// VERSION_V1.md). No backend yet, so this is a single in-memory
// ChangeNotifier singleton — good enough for today's testable build,
// and the natural seam to swap for real persistence (Supabase) later.

import 'package:flutter/foundation.dart';
import '../models/journey_match.dart';
import '../models/seeker_profile.dart';
import '../services/zyra_wali_link_service.dart';

enum ZyraPlan { basic, one }

class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  // Own profile — filled in as onboarding chapters complete.
  String? name;
  String? gender;
  DateTime? dob;
  List<String> photos = [];
  String? location;
  String? sect;
  ZyraPlan plan = ZyraPlan.basic;

  // Notification preferences (2026-07-26, Settings build-out). No push
  // notification system exists in this build yet (no Bell icon, no
  // delivery mechanism, no backend table) — these are preference
  // toggles only, captured now so they're ready to wire up the moment
  // real notifications are built, per NotificationSettingsScreen's own
  // on-screen disclosure. In-memory only, like the rest of AppState.
  bool notifyNewMatches = true;
  bool notifyNewMessages = true;
  bool notifyWaliRequests = true;

  void setNotificationPreference({bool? newMatches, bool? newMessages, bool? waliRequests}) {
    if (newMatches != null) notifyNewMatches = newMatches;
    if (newMessages != null) notifyNewMessages = newMessages;
    if (waliRequests != null) notifyWaliRequests = waliRequests;
    notifyListeners();
  }

  // Wali identity — separate from the Seeker profile fields above per
  // WALI_ARCHITECTURE_CURRENT_VERSION_V5.md: "Wali accounts carry
  // identity only" and are entirely separate from a Seeker account (a
  // person cannot be both on the same account). Kept minimal since the
  // onboarding content itself is a v1 draft — see DR-ZYRA-081.
  String? waliName;
  String? waliRelationship; // Father / Grandfather / Brother / Paternal Uncle / Other
  bool waliHasExtendedWali = false; // Path 2A mock — £9.99/month independent purchase

  // Superseded by waliRealLinkedSeekers below (2026-07-18, real Wali
  // linking) — kept to avoid touching any other reference, but no
  // longer written to.
  final List<SeekerProfile> waliLinkedSeekers = [];

  // Real linked Seekers, fetched via ZyraWaliLinkService.fetchLinkedPeople
  // (asWali: true) from the live wali_links table. Deliberately just
  // id/firstName — Journey/Timeline visibility for a Wali isn't built
  // yet, so this only supports "who is linked", not "what's happening
  // in their Journey".
  List<WaliLinkedPerson> waliRealLinkedSeekers = [];

  void setWaliRealLinkedSeekers(List<WaliLinkedPerson> people) {
    waliRealLinkedSeekers = people;
    notifyListeners();
  }

  void saveWaliOnboarding({required String name, required String relationship}) {
    waliName = name;
    waliRelationship = relationship;
    notifyListeners();
  }

  void setWaliExtendedWali(bool value) {
    waliHasExtendedWali = value;
    notifyListeners();
  }

  // Browse decisions.
  final List<SeekerProfile> declined = [];
  final List<SeekerProfile> saved = [];
  final List<SeekerProfile> outgoingLikes = [];

  // Journeys — per MATCH_UX_SPEC: Match event (mutual Like) creates a
  // Potential Journey; the Pre-Journey Ritual (ZyraJourneyService.
  // promoteToActive, a real RPC) promotes it to an Active Journey.
  // Real matches.status/journey_stage now back this directly (2026-07-25
  // migration) — these lists are populated wholesale via
  // setJourneyMatches() after a ZyraJourneyService.fetchJourneyMatches()
  // call, not mutated locally.
  List<JourneyMatch> potentialJourneys = [];
  List<JourneyMatch> activeJourneys = [];

  /// Replaces both Journey lists wholesale from a fresh
  /// ZyraJourneyService.fetchJourneyMatches() read — the way screens
  /// refresh Journey state after any promote/suspend/resume/end call,
  /// now that Journey lifecycle is real backend state rather than a
  /// local synchronous mutation.
  void setJourneyMatches({required List<JourneyMatch> potential, required List<JourneyMatch> active}) {
    potentialJourneys = potential;
    activeJourneys = active;
    notifyListeners();
  }

  void saveChapter1({required String name, required String gender, required DateTime dob}) {
    this.name = name;
    this.gender = gender;
    this.dob = dob;
    notifyListeners();
  }

  void saveChapter2({required List<String> photos, String? location, String? sect}) {
    this.photos = photos;
    this.location = location;
    this.sect = sect;
    notifyListeners();
  }

  void decline(SeekerProfile p) {
    declined.add(p);
    saved.remove(p);
    outgoingLikes.remove(p);
    notifyListeners();
  }

  void save(SeekerProfile p) {
    if (!saved.contains(p)) saved.add(p);
    notifyListeners();
  }

  /// Returns true if this Like created a Match event (mutual Like) —
  /// per PROFILE DECISION SYSTEM/Summary.md: "Mutual Like = Match event
  /// = Potential Journey created." Mock profiles flagged
  /// `alreadyLikedYou` simulate the other Seeker's prior Like so a Match
  /// is deterministically reachable for testing.
  ///
  /// 2026-07-25: no longer touches potentialJourneys — that list is now
  /// real backend state (matches.status='potential'), populated wholesale
  /// via setJourneyMatches() after a ZyraJourneyService.fetchJourneyMatches()
  /// call. This method's return value is UI-only: browse_screen.dart uses
  /// it purely to decide whether to show the Match Notification screen
  /// for mock/demo profiles. The real match path (real Seekers) is
  /// entirely separate — ZyraDiscoveryService.recordLike() writes to the
  /// real `likes` table, and the create_match_on_mutual_like trigger
  /// creates the real `matches` row server-side.
  bool like(SeekerProfile p) {
    if (!outgoingLikes.contains(p)) outgoingLikes.add(p);
    final isMatch = p.alreadyLikedYou;
    notifyListeners();
    return isMatch;
  }

  /// Developer Mode preset support (2026-07-19, Founder request) —
  /// resets all session-scoped state and applies a scenario in one
  /// step, so switching test accounts never leaks the previous
  /// scenario's Browse decisions, journeys, or profile fields into the
  /// next one. Only called from DeveloperAccessScreen.
  void applyDevPreset({
    String? name,
    String? gender,
    DateTime? dob,
    ZyraPlan plan = ZyraPlan.basic,
    String? location,
    String? waliName,
    String? waliRelationship,
    bool waliHasExtendedWali = false,
  }) {
    this.name = name;
    this.gender = gender;
    this.dob = dob;
    this.plan = plan;
    this.location = location;
    photos = [];
    sect = null;
    this.waliName = waliName;
    this.waliRelationship = waliRelationship;
    this.waliHasExtendedWali = waliHasExtendedWali;
    waliRealLinkedSeekers = [];
    declined.clear();
    saved.clear();
    outgoingLikes.clear();
    potentialJourneys.clear();
    activeJourneys.clear();
    notifyListeners();
  }

  /// Mock plan change — real purchase flow (App Store/Play Store IAP,
  /// or Stripe for web) is not built yet; this just flips the local
  /// entitlement so tier-gated UI (Incoming Potentials, daily limits,
  /// Pause Journey, etc. per ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V3.md §6-7)
  /// is testable today.
  void setPlan(ZyraPlan newPlan) {
    plan = newPlan;
    notifyListeners();
  }
}
