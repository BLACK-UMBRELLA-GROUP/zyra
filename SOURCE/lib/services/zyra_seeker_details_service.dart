// Chapter 2 persistence — Founder approved 2026-08-04.
//
// Before this, onboarding collected 31 values and persisted ONE (the city,
// wired 2026-08-04). `AppState.saveChapter2()` assigned three fields and
// called notifyListeners(). Close the app and Chapter 2 was gone.
//
// THE RULE THIS FILE EXISTS TO ENFORCE: store the code, never the label.
//
// Ratified when the production reference lists landed, and until today
// completely unexercised — `zyraCodeFor()` had zero callers anywhere in
// the project. The pickers hand back DISPLAY STRINGS ("Pakistan",
// "Punjabi"), so every write has to convert and every read has to convert
// back. That conversion is this file's main job.
//
// Why it matters concretely: ISO 639-1 names two of this audience's
// most-spoken languages "Panjabi" and "Pushto" — spellings nobody would
// search for. Those labels are corrected in the reference data while the
// codes stay canonical. Had the label been the stored value, fixing the
// spelling would have orphaned every affected user's row.
//
// The database enforces this independently: CHECK constraints reject
// 'Pakistan' for a country and 'Pakistani' for an ethnicity outright.
// Verified 2026-08-04 — five label forms rejected, code row accepted.
//
// ARTICLE 9. Sect, revert status, ethnicity, country of birth and
// nationality are special-category data under UK GDPR. `saveDetails`
// refuses to write them without a recorded consent (see
// ZyraConsentService). That check is here rather than only in the UI
// because a screen can be skipped, reordered or bypassed by a deep link,
// and this is the single point every write passes through.
//
// The Founder has confirmed a solicitor will review the consent wording,
// Privacy Policy, Terms and the Compatibility Unlock flow before public
// launch. NOT LEGAL ADVICE.

import 'package:flutter/foundation.dart';

import '../data/zyra_reference_data.dart';
import '../main.dart';
import '../models/onboarding_question.dart';
import 'zyra_auth.dart';
import 'zyra_consent_service.dart';

/// One Seeker's Chapter 2 answers, in DISPLAY form.
///
/// Codes live in the database; this object holds labels, because that is
/// what every widget wants and what the pickers produce. Conversion
/// happens at the boundary — [toRow] on the way down, [fromRow] on the way
/// up — so no screen ever has to know a code exists.
class SeekerDetails {
  final String? sect;          // 'Sunni' | 'Shia' | free text when Other
  final bool? revertStatus;
  final String? countryOfBirth;
  final String? nationality;   // demonym, e.g. 'Pakistani'
  final String? ethnicity;
  final List<String> languages;
  final Map<String, dynamic> preferences;

  const SeekerDetails({
    this.sect,
    this.revertStatus,
    this.countryOfBirth,
    this.nationality,
    this.ethnicity,
    this.languages = const [],
    this.preferences = const {},
  });

  /// Display labels -> stored codes.
  ///
  /// An unrecognised label is a BUG, not a value: it means a picker and the
  /// reference list have drifted apart. `zyraCodeFor` returns null in that
  /// case and its own doc comment says callers must never store it. So an
  /// unconvertible answer is dropped and logged loudly rather than written
  /// as-is — writing the label would defeat the entire rule and the CHECK
  /// constraint would reject it anyway.
  Map<String, dynamic> toRow(String userId) {
    String? code(List<ZyraRefItem> list, String? label, String field) {
      if (label == null) return null;
      final c = zyraCodeFor(list, label);
      if (c == null) {
        debugPrint('ZYRA: no reference code for $field="$label" — NOT SAVED. '
            'A picker and zyra_reference_data have drifted apart.');
      }
      return c;
    }

    // Sect is a fixed three-value list, not a reference list. 'Other'
    // carries the user's own words in sect_other.
    final isOther = sect != null && sect != 'Sunni' && sect != 'Shia';
    final sectCode = sect == null
        ? null
        : sect == 'Sunni'
            ? 'sunni'
            : sect == 'Shia'
                ? 'shia'
                : 'other';

    final countryCode = countryOfBirth == null
        ? null
        : zyraCountryCodeFor(countryOfBirth);
    final natCode = nationality == null
        ? null
        : zyraNationalityCodeFor(nationality);
    if (countryOfBirth != null && countryCode == null) {
      debugPrint('ZYRA: no ISO code for country_of_birth="$countryOfBirth" — NOT SAVED.');
    }
    if (nationality != null && natCode == null) {
      debugPrint('ZYRA: no ISO code for nationality="$nationality" — NOT SAVED.');
    }

    final langCodes = <String>[];
    for (final l in languages) {
      final c = zyraCodeFor(zyraLanguages, l);
      if (c == null) {
        debugPrint('ZYRA: no ISO 639-1 code for language="$l" — NOT SAVED.');
      } else {
        langCodes.add(c);
      }
    }

    return {
      'user_id': userId,
      'sect': sectCode,
      // Capped at 60 to match the CHECK constraint, so an over-long answer
      // is truncated here rather than failing the whole write.
      'sect_other': isOther && sect != null
          ? (sect!.length > 60 ? sect!.substring(0, 60) : sect)
          : null,
      'revert_status': revertStatus,
      'country_of_birth': countryCode,
      'nationality': natCode,
      'ethnicity': code(zyraEthnicities, ethnicity, 'ethnicity'),
      'languages': langCodes,
      'preferences': preferences,
    };
  }

  /// Stored codes -> display labels.
  static SeekerDetails fromRow(Map<String, dynamic> r) {
    String? label(List<ZyraRefItem> list, Object? code) {
      if (code == null) return null;
      for (final i in list) {
        if (i.code == code) return i.name;
      }
      // A code with no label means the reference list dropped an entry
      // that users already hold. Surfaced rather than rendered blank.
      debugPrint('ZYRA: stored code "$code" has no label in the current '
          'reference list — an entry was removed without a migration.');
      return null;
    }

    final sectCode = r['sect'] as String?;
    return SeekerDetails(
      sect: switch (sectCode) {
        'sunni' => 'Sunni',
        'shia' => 'Shia',
        'other' => r['sect_other'] as String?,
        _ => null,
      },
      revertStatus: r['revert_status'] as bool?,
      countryOfBirth: () {
        final c = r['country_of_birth'];
        if (c == null) return null;
        for (final x in zyraCountries) {
          if (x.code == c) return x.name;
        }
        return null;
      }(),
      nationality: () {
        final c = r['nationality'];
        if (c == null) return null;
        for (final x in zyraCountries) {
          if (x.code == c) return x.nationality;
        }
        return null;
      }(),
      ethnicity: label(zyraEthnicities, r['ethnicity']),
      languages: [
        for (final c in (r['languages'] as List? ?? const []))
          ?label(zyraLanguages, c),
      ],
      preferences: Map<String, dynamic>.from(r['preferences'] as Map? ?? const {}),
    );
  }
}

class ZyraSeekerDetailsService {
  ZyraSeekerDetailsService._();

  /// Serialises the traffic-light structures Chapter 2 collects.
  ///
  /// Uses the SAME green/yellow/red vocabulary as
  /// `onboarding_answers.ch4_preferences`, deliberately: `score_candidates()`
  /// already reads that vocabulary in Postgres, so a future Chapter-2-aware
  /// scorer reuses its logic unchanged instead of learning a second dialect.
  static Map<String, dynamic> buildPreferences({
    String? distancePref,
    TrafficLight? distanceFlex,
    Map<String, TrafficLight> sectMatrix = const {},
    bool sectHardReq = false,
    TrafficLight? sectOutsideFlex,
    TrafficLight? revertFlex,
    List<String> countryPrefs = const [],
    bool countrySkipped = false,
    TrafficLight? countryFlex,
    List<String> nationalityPrefs = const [],
    bool nationalitySkipped = false,
    TrafficLight? nationalityFlex,
    List<String> ethnicityPrefs = const [],
    bool ethnicitySkipped = false,
    TrafficLight? ethnicityFlex,
    List<String> languagePrefs = const [],
    bool languageSkipped = false,
    TrafficLight? languageFlex,
  }) {
    List<String> codes(List<ZyraRefItem> list, List<String> labels) =>
        [for (final l in labels) ?zyraCodeFor(list, l)];

    return {
      'location': {
        'preference': zyraCodeFor(zyraLocationPreferences, distancePref),
        'flexibility': distanceFlex?.name,
      },
      'sect': {
        // Keyed by the on-screen option, which for 'Other' is the user's
        // own words — there is no code for it by definition.
        'matrix': {for (final e in sectMatrix.entries) e.key: e.value.name},
        'hard_requirement': sectHardReq,
        'outside_flexibility': sectOutsideFlex?.name,
      },
      'revert': {'flexibility': revertFlex?.name},
      'country_of_birth': {
        'preferred': codes(
          [for (final c in zyraCountries) ZyraRefItem(c.code, c.name)],
          countryPrefs,
        ),
        'skipped': countrySkipped,
        'flexibility': countryFlex?.name,
      },
      'nationality': {
        'preferred': [
          for (final l in nationalityPrefs) ?zyraNationalityCodeFor(l),
        ],
        'skipped': nationalitySkipped,
        'flexibility': nationalityFlex?.name,
      },
      'ethnicity': {
        'preferred': codes(zyraEthnicities, ethnicityPrefs),
        'skipped': ethnicitySkipped,
        'flexibility': ethnicityFlex?.name,
      },
      'languages': {
        'preferred': codes(zyraLanguages, languagePrefs),
        'skipped': languageSkipped,
        'flexibility': languageFlex?.name,
      },
    };
  }

  /// Writes the signed-in Seeker's Chapter 2 answers.
  ///
  /// Returns false without writing if Article 9 consent has not been
  /// recorded. That is not belt-and-braces: a UI gate can be skipped by a
  /// deep link, a reordered flow or a future refactor, and this is the one
  /// place every write passes through.
  static Future<bool> saveDetails(SeekerDetails d) async {
    final user = ZyraAuth.currentUser;
    if (user == null) return false;   // mock/offline session — nothing to write

    if (!await ZyraConsentService.hasArticle9Consent()) {
      debugPrint('ZYRA: refusing to save Chapter 2 — no Article 9 consent on '
          'record for this user. Special-category data (religious belief, '
          'ethnic origin) must not be stored without it.');
      return false;
    }

    try {
      await supabase.from('seeker_details').upsert(d.toRow(user.id));
      return true;
    } catch (e) {
      // Logged, never silent (ES-08). These answers are half the input the
      // compatibility score will ever have; a persistent failure here makes
      // the premium feature compute from nothing while the app looks fine.
      debugPrint('ZYRA: saveDetails failed — Chapter 2 answers not persisted. $e');
      return false;
    }
  }

  /// The signed-in Seeker's own answers, for re-entering Chapter 2.
  static Future<SeekerDetails?> fetchOwn() async {
    final user = ZyraAuth.currentUser;
    if (user == null) return null;
    try {
      final row = await supabase
          .from('seeker_details')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      return row == null ? null : SeekerDetails.fromRow(row);
    } catch (e) {
      debugPrint('ZYRA: fetchOwn seeker_details failed — $e');
      return null;
    }
  }

  /// Another Seeker's answers, and ONLY if this user has unlocked them.
  ///
  /// Goes through `seeker_details_for_unlocked()`, a SECURITY DEFINER
  /// function that checks `profile_unlocks` first. There is deliberately no
  /// RLS policy letting one Seeker select this table directly — verified
  /// 2026-08-04: a user holding a real unlock still reads zero rows by
  /// direct select, and gets the data only through this call.
  ///
  /// Returns null when not unlocked, which is indistinguishable from "no
  /// answers recorded". That is intended — the absence of a purchase should
  /// not be reported differently from the absence of data.
  static Future<SeekerDetails?> fetchUnlocked(String profileId) async {
    if (ZyraAuth.currentUser == null) return null;
    try {
      final rows = await supabase
          .rpc('seeker_details_for_unlocked', params: {'p_target': profileId}) as List?;
      if (rows == null || rows.isEmpty) return null;
      return SeekerDetails.fromRow(Map<String, dynamic>.from(rows.first as Map));
    } catch (e) {
      debugPrint('ZYRA: fetchUnlocked($profileId) failed — $e');
      return null;
    }
  }
}
