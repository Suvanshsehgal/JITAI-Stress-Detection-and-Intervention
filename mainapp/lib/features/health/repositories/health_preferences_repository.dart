import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_permission.dart';

abstract class HealthPreferencesRepository {
  bool isSourceEnabled(HealthDataType type);
  Future<void> setSourceEnabled(HealthDataType type, bool enabled);
  Set<String> getAllEnabledPreferenceIds();
  Future<void> setAllEnabledPreferenceIds(Set<String> ids);
}

class LocalHealthPreferencesRepository implements HealthPreferencesRepository {
  final SharedPreferences _prefs;
  static const String _prefsKey = 'onboardingDataPrefs';

  LocalHealthPreferencesRepository(this._prefs);

  @override
  Set<String> getAllEnabledPreferenceIds() {
    return _prefs.getStringList(_prefsKey)?.toSet() ?? {};
  }

  @override
  bool isSourceEnabled(HealthDataType type) {
    final enabledIds = getAllEnabledPreferenceIds();
    return enabledIds.contains(type.preferenceKey);
  }

  @override
  Future<void> setSourceEnabled(HealthDataType type, bool enabled) async {
    final current = getAllEnabledPreferenceIds();
    final updated = Set<String>.from(current);
    if (enabled) {
      updated.add(type.preferenceKey);
    } else {
      updated.remove(type.preferenceKey);
    }
    await setAllEnabledPreferenceIds(updated);
  }

  @override
  Future<void> setAllEnabledPreferenceIds(Set<String> ids) async {
    await _prefs.setStringList(_prefsKey, ids.toList());
  }
}
