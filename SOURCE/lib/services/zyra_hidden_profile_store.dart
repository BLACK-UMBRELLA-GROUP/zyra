// Account-scoped local fixtures for Settings -> Hidden Profiles.
//
// Real personal hides are server-owned, separate from safety blocks. Never
// retain or rehydrate a real UUID's identity summary as an alternative access
// route. Legacy real records are removed from this cache on read. They are not
// converted into personal hides and no existing block is changed.
//
// Developer Browse profiles have deliberately non-UUID ids and no server row.
// Their hide/report state lives here entirely so the complete experience can
// be tested without ever sending a fake id to Supabase.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/seeker_profile.dart';
import 'zyra_auth.dart';
import 'zyra_report_service.dart';

@immutable
class ZyraHiddenProfileRecord {
  final String id;
  final String firstName;
  final String? surnameLine;
  final int age;
  final String city;
  final String gender;
  final bool isDemo;

  const ZyraHiddenProfileRecord({
    required this.id,
    required this.firstName,
    required this.age,
    required this.city,
    required this.gender,
    required this.isDemo,
    this.surnameLine,
  });

  factory ZyraHiddenProfileRecord.fromProfile(SeekerProfile profile) =>
      ZyraReportService.isPersistableId(profile.id)
      ? ZyraHiddenProfileRecord.fallback(profile.id)
      : ZyraHiddenProfileRecord(
          id: profile.id,
          firstName: profile.firstName,
          surnameLine: profile.surnameLine,
          age: profile.age,
          city: profile.city,
          gender: profile.gender,
          isDemo: !ZyraReportService.isPersistableId(profile.id),
        );

  factory ZyraHiddenProfileRecord.fallback(String id) =>
      ZyraHiddenProfileRecord(
        id: id,
        firstName: 'Hidden profile',
        age: 0,
        city: '',
        gender: '',
        isDemo: !ZyraReportService.isPersistableId(id),
      );

  factory ZyraHiddenProfileRecord.fromJson(Map<String, dynamic> json) =>
      ZyraReportService.isPersistableId(json['id'] as String)
      ? ZyraHiddenProfileRecord.fallback(json['id'] as String)
      : ZyraHiddenProfileRecord(
          id: json['id'] as String,
          firstName: (json['first_name'] as String?) ?? 'Hidden profile',
          surnameLine: json['surname_line'] as String?,
          age: (json['age'] as num?)?.toInt() ?? 0,
          city: (json['city'] as String?) ?? 'Details unavailable',
          gender: (json['gender'] as String?) ?? '',
          isDemo: json['is_demo'] == true,
        );

  Map<String, dynamic> toJson() => ZyraReportService.isPersistableId(id)
      ? {'id': id}
      : {
          'id': id,
          'first_name': firstName,
          'surname_line': surnameLine,
          'age': age,
          'city': city,
          'gender': gender,
          'is_demo': isDemo,
        };

  String get displayName {
    final surname = surnameLine?.trim();
    return surname == null || surname.isEmpty
        ? firstName
        : '$firstName $surname';
  }
}

abstract final class ZyraHiddenProfileStore {
  static const _keyPrefix = 'zyra.hidden_profiles.v1.';
  static int _epoch = 0;
  static Future<void> _mutations = Future<void>.value();

  /// Invalidates reads in flight; persisted summaries keep their own owner.
  static void clearForAccountChange() => _epoch++;

  static String get _accountScope {
    try {
      return ZyraAuth.currentUser?.id ?? 'developer_preview';
    } catch (_) {
      // Unit tests and the pre-auth developer preview can exist before
      // Supabase is initialised. They still need a deterministic local scope.
      return 'developer_preview';
    }
  }

  static Future<List<ZyraHiddenProfileRecord>> records() async {
    final owner = _accountScope;
    final epoch = _epoch;
    final result = await _read(owner, epoch);
    return _isCurrent(owner, epoch) ? result : const [];
  }

  static bool _isCurrent(String owner, int epoch) =>
      epoch == _epoch && owner == _accountScope;

  static Future<List<ZyraHiddenProfileRecord>> _read(
    String owner,
    int epoch,
  ) async {
    final key = '$_keyPrefix$owner';
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final records = <ZyraHiddenProfileRecord>[];
      var discardedRealIdentity = false;
      for (final item in decoded) {
        if (item is! Map) continue;
        final id = item['id'];
        if (id is! String || id.isEmpty) continue;
        if (ZyraReportService.isPersistableId(id)) {
          discardedRealIdentity = true;
          continue;
        }
        // Only explicit local fixtures may retain display details.
        if (item['is_demo'] != true) continue;
        try {
          records.add(
            ZyraHiddenProfileRecord.fromJson(Map<String, dynamic>.from(item)),
          );
        } catch (_) {
          // A malformed local fixture must not prevent retiring another
          // record's real identity fields during the same read.
        }
      }
      if (discardedRealIdentity && _isCurrent(owner, epoch)) {
        if (records.isEmpty) {
          await prefs.remove(key);
        } else {
          await prefs.setString(
            key,
            jsonEncode([for (final record in records) record.toJson()]),
          );
        }
      }
      return records;
    } catch (e) {
      debugPrint('ZYRA: hidden-profile cache could not be read. $e');
      return const [];
    }
  }

  static Future<void> _mutate(
    Future<void> Function(String owner, int epoch) operation,
  ) {
    final owner = _accountScope;
    final epoch = _epoch;
    // Capturing before queueing preserves invocation order without letting an
    // old account's queued mutation bind to the new account when it executes.
    final next = _mutations.then((_) async {
      if (_isCurrent(owner, epoch)) await operation(owner, epoch);
    });
    _mutations = next.catchError((Object _) {
      debugPrint('ZYRA: hidden-profile cache mutation could not complete.');
    });
    return _mutations;
  }

  static Future<void> remember(SeekerProfile profile) =>
      _mutate((owner, epoch) async {
        final current = await _read(owner, epoch);
        if (!_isCurrent(owner, epoch)) return;
        // A successful Block/report must not create a personal Hide or a
        // cached real identity. Reading above also retires legacy summaries.
        if (ZyraReportService.isPersistableId(profile.id)) return;
        final next = <ZyraHiddenProfileRecord>[
          ZyraHiddenProfileRecord.fromProfile(profile),
          for (final record in current)
            if (record.id != profile.id) record,
        ];
        await _write(next, owner: owner, epoch: epoch);
      });

  static Future<void> forget(String profileId) => _mutate((owner, epoch) async {
    final current = await _read(owner, epoch);
    if (!_isCurrent(owner, epoch)) return;
    await _write(
      [
        for (final record in current)
          if (record.id != profileId) record,
      ],
      owner: owner,
      epoch: epoch,
    );
  });

  static Future<Set<String>> hiddenIds() async {
    final owner = _accountScope;
    final epoch = _epoch;
    final saved = await records();
    if (!_isCurrent(owner, epoch)) return {};
    return {for (final record in saved) record.id};
  }

  static Future<void> _write(
    List<ZyraHiddenProfileRecord> records, {
    required String owner,
    required int epoch,
  }) async {
    final key = '$_keyPrefix$owner';
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!_isCurrent(owner, epoch)) return;
      if (records.isEmpty) {
        await prefs.remove(key);
        return;
      }
      await prefs.setString(
        key,
        jsonEncode([
          for (final record in records)
            if (record.isDemo && !ZyraReportService.isPersistableId(record.id))
              record.toJson(),
        ]),
      );
    } catch (e) {
      // Local fixture persistence cannot undo a separately confirmed safety
      // operation or become authority for a real personal-hide preference.
      debugPrint('ZYRA: hidden-profile cache could not be written. $e');
    }
  }
}
