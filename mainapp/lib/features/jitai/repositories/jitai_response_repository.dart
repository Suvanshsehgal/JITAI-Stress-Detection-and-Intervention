import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/jitai_user_response.dart';

abstract class JitaiResponseRepository {
  Future<void> recordResponse(JitaiUserResponse response);
  Future<List<JitaiUserResponse>> getAllResponses();
  Future<List<JitaiUserResponse>> getPendingResponses();
  Future<void> markAsSynced(List<String> ids);
}

class LocalJitaiResponseRepository implements JitaiResponseRepository {
  final SharedPreferences _prefs;
  static const String _storageKey = 'jitai_user_responses_v1';

  LocalJitaiResponseRepository(this._prefs);

  @override
  Future<void> recordResponse(JitaiUserResponse response) async {
    final list = await getAllResponses();
    // Replace or add
    final index = list.indexWhere((r) => r.id == response.id);
    if (index >= 0) {
      list[index] = response;
    } else {
      list.insert(0, response);
    }
    await _saveList(list);
  }

  @override
  Future<List<JitaiUserResponse>> getAllResponses() async {
    final raw = _prefs.getStringList(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      return raw
          .map((item) => JitaiUserResponse.fromJson(jsonDecode(item) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<JitaiUserResponse>> getPendingResponses() async {
    final list = await getAllResponses();
    return list.where((r) => r.syncStatus != SyncStatus.synced).toList();
  }

  @override
  Future<void> markAsSynced(List<String> ids) async {
    final list = await getAllResponses();
    final updated = list.map((r) {
      if (ids.contains(r.id)) {
        return r.copyWith(syncStatus: SyncStatus.synced);
      }
      return r;
    }).toList();
    await _saveList(updated);
  }

  Future<void> _saveList(List<JitaiUserResponse> list) async {
    final encoded = list.map((r) => jsonEncode(r.toJson())).toList();
    await _prefs.setStringList(_storageKey, encoded);
  }
}
