import 'package:shared_preferences/shared_preferences.dart';

abstract class TokenStorage {
  Future<void> saveToken(String token);
  String? getToken();
  Future<void> clearToken();
}

class SharedPrefsTokenStorage implements TokenStorage {
  final SharedPreferences _prefs;
  static const String _tokenKey = 'ebb_auth_access_token_v1';

  SharedPrefsTokenStorage(this._prefs);

  @override
  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  @override
  String? getToken() {
    return _prefs.getString(_tokenKey);
  }

  @override
  Future<void> clearToken() async {
    await _prefs.remove(_tokenKey);
  }
}
