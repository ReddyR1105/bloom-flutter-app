import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../integration/bloom_gateway.dart';

/// One versioned value prevents partially saved combinations of preferences.
class SettingsStore {
  SettingsStore(this.preferences);
  final SharedPreferences preferences;
  static const key = 'bloom.settings.v1';

  SettingsView load() {
    final raw = preferences.get(key);
    if (raw == null) return const SettingsView();
    try {
      final value = jsonDecode(raw as String) as Map<String, dynamic>;
      if (value['defaultTarget'] is! int ||
          value['weekStartsMonday'] is! bool ||
          value['reducedMotion'] is! bool) {
        throw const FormatException();
      }
      final result = SettingsView(
        defaultTarget: value['defaultTarget'] as int,
        weekStartsMonday: value['weekStartsMonday'] as bool,
        reducedMotion: value['reducedMotion'] as bool,
      );
      _validate(result);
      return result;
    } catch (_) {
      throw StateError(
        'Saved Bloom settings are corrupt. Restore valid settings explicitly.',
      );
    }
  }

  Future<void> save(SettingsView value) async {
    _validate(value);
    try {
      final saved = await preferences.setString(
        key,
        jsonEncode({
          'defaultTarget': value.defaultTarget,
          'weekStartsMonday': value.weekStartsMonday,
          'reducedMotion': value.reducedMotion,
        }),
      );
      if (!saved) {
        throw StateError('Settings could not be saved. Please retry.');
      }
    } catch (_) {
      // Legacy SharedPreferences updates its cache before the platform responds.
      // Reload so a failed write cannot look like a successful save in load().
      await preferences.reload();
      rethrow;
    }
  }

  void _validate(SettingsView value) {
    if (value.defaultTarget < 1 || value.defaultTarget > 100000) {
      throw ArgumentError('Default target must be 1–100000.');
    }
  }
}
