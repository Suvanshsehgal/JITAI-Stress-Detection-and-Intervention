import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// Error from Supabase Auth or PostgREST. [code] is the Postgres/Supabase
/// error code when there is one (for example "23505" = duplicate key).
class SupabaseException implements Exception {
  SupabaseException(this.message, {this.status, this.code});

  final String message;
  final int? status;
  final String? code;

  @override
  String toString() => message;
}

/// A signed-in session, stored on this device.
class SupabaseSession {
  const SupabaseSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.userId,
    this.email,
    this.username,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String userId;
  final String? email;
  final String? username;

  bool get isExpiringSoon =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(seconds: 60)));

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_at': expiresAt.millisecondsSinceEpoch,
        'user_id': userId,
        'email': email,
        'username': username,
      };

  factory SupabaseSession.fromJson(Map<String, dynamic> j) => SupabaseSession(
        accessToken: j['access_token'] as String,
        refreshToken: (j['refresh_token'] as String?) ?? '',
        expiresAt: DateTime.fromMillisecondsSinceEpoch(j['expires_at'] as int),
        userId: j['user_id'] as String,
        email: j['email'] as String?,
        username: j['username'] as String?,
      );
}

/// Talks to Supabase with plain HTTP: no SDK, no extra dependency.
/// Auth endpoints: /auth/v1. Table endpoints: /rest/v1 (row-level security applies).
class SupabaseAuthService {
  SupabaseAuthService({required SharedPreferences prefs, http.Client? client})
      : _prefs = prefs,
        _client = client ?? http.Client();

  static const String _sessionKey = 'supabase_session_v1';
  static const Duration _timeout = Duration(seconds: 15);

  final SharedPreferences _prefs;
  final http.Client _client;

  Uri _authUri(String path, {String? query}) => Uri.parse(
      '${AppConfig.supabaseUrl}/auth/v1$path${query == null ? '' : '?$query'}');

  Uri _restUri(String pathAndQuery) =>
      Uri.parse('${AppConfig.supabaseUrl}/rest/v1$pathAndQuery');

  Map<String, String> get _anonHeaders => {
        'apikey': AppConfig.supabaseAnonKey,
        'Content-Type': 'application/json',
      };

  Map<String, String> _userHeaders(String token) => {
        'apikey': AppConfig.supabaseAnonKey,
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  /// Runs one request and returns the decoded JSON body (or null for an empty body).
  Future<dynamic> _send(Future<http.Response> Function() call) async {
    http.Response res;
    try {
      res = await call().timeout(_timeout);
    } on TimeoutException {
      throw SupabaseException('Request timed out. Check your connection and try again.');
    } catch (_) {
      throw SupabaseException('Could not reach the server. Check your connection.');
    }

    dynamic body;
    if (res.body.isNotEmpty) {
      try {
        body = jsonDecode(res.body);
      } catch (_) {
        body = null;
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    String? message;
    String? code;
    if (body is Map) {
      message = (body['msg'] ??
              body['error_description'] ??
              body['message'] ??
              body['error'])
          ?.toString();
      code = body['code']?.toString();
    }
    throw SupabaseException(
      message ?? 'Request failed (${res.statusCode})',
      status: res.statusCode,
      code: code,
    );
  }

  SupabaseSession? _sessionFromAuthJson(dynamic json) {
    if (json is! Map || json['access_token'] == null) return null;
    final user = (json['user'] as Map?) ?? const {};
    final meta = (user['user_metadata'] as Map?) ?? const {};
    final expiresIn = (json['expires_in'] as num?)?.toInt() ?? 3600;
    return SupabaseSession(
      accessToken: json['access_token'] as String,
      refreshToken: (json['refresh_token'] as String?) ?? '',
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      userId: user['id'] as String,
      email: user['email'] as String?,
      username: meta['username'] as String?,
    );
  }

  // ---------------------------------------------------------------- session

  Future<void> _save(SupabaseSession s) =>
      _prefs.setString(_sessionKey, jsonEncode(s.toJson()));

  Future<void> clearSession() => _prefs.remove(_sessionKey);

  /// The stored session, read without network. Use it on startup so the
  /// router does not flash the login screen.
  SupabaseSession? storedSession() {
    final raw = _prefs.getString(_sessionKey);
    if (raw == null) return null;
    try {
      return SupabaseSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// The stored session, refreshed first if its access token is close to expiry.
  /// Returns null when there is no session or the refresh was rejected.
  Future<SupabaseSession?> currentSession() async {
    var s = storedSession();
    if (s == null) return null;
    if (!s.isExpiringSoon) return s;
    try {
      s = await _refresh(s);
      return s;
    } on SupabaseException catch (e) {
      // 400/401: the refresh token is no longer valid, so the user must sign in again.
      // Anything else (offline, timeout) keeps the old session for now.
      if (e.status == 400 || e.status == 401) {
        await clearSession();
        return null;
      }
      return s;
    }
  }

  /// A valid access token, or null when signed out.
  Future<String?> accessToken() async => (await currentSession())?.accessToken;

  Future<SupabaseSession> _refresh(SupabaseSession s) async {
    final json = await _send(() => _client.post(
          _authUri('/token', query: 'grant_type=refresh_token'),
          headers: _anonHeaders,
          body: jsonEncode({'refresh_token': s.refreshToken}),
        ));
    final next = _sessionFromAuthJson(json);
    if (next == null) {
      throw SupabaseException('Session expired. Please sign in again.', status: 401);
    }
    await _save(next);
    return next;
  }

  // ------------------------------------------------------------------- auth

  /// Returns the session when Supabase signs the user in straight away.
  /// Returns null when email confirmation is required first.
  Future<SupabaseSession?> signUp({
    required String email,
    required String password,
    Map<String, dynamic> data = const {},
  }) async {
    final json = await _send(() => _client.post(
          _authUri('/signup'),
          headers: _anonHeaders,
          body: jsonEncode({'email': email, 'password': password, 'data': data}),
        ));
    final s = _sessionFromAuthJson(json);
    if (s != null) await _save(s);
    return s;
  }

  Future<SupabaseSession> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final json = await _send(() => _client.post(
          _authUri('/token', query: 'grant_type=password'),
          headers: _anonHeaders,
          body: jsonEncode({'email': email, 'password': password}),
        ));
    final s = _sessionFromAuthJson(json);
    if (s == null) {
      throw SupabaseException('Sign in failed. Please try again.');
    }
    await _save(s);
    return s;
  }

  /// Ends the session on the server (best effort) and clears it on this device.
  Future<void> signOut() async {
    final raw = storedSession();
    if (raw != null) {
      try {
        await _send(() => _client.post(
              _authUri('/logout'),
              headers: _userHeaders(raw.accessToken),
            ));
      } catch (_) {
        // Offline logout still clears the local session.
      }
    }
    await clearSession();
  }

  // ------------------------------------------------------------------ tables

  /// GET /rest/v1/[table]?[query]. Example query: "select=username&id=eq.<uid>".
  Future<List<Map<String, dynamic>>> select(
    String table, {
    required String query,
    required String token,
  }) async {
    final json = await _send(
        () => _client.get(_restUri('/$table?$query'), headers: _userHeaders(token)));
    if (json is! List) return const [];
    return json.cast<Map<String, dynamic>>();
  }

  /// Insert or update by primary key (merge-duplicates).
  Future<void> upsert(
    String table,
    Map<String, dynamic> row, {
    required String token,
  }) async {
    await _send(() => _client.post(
          _restUri('/$table'),
          headers: {
            ..._userHeaders(token),
            'Prefer': 'resolution=merge-duplicates,return=minimal',
          },
          body: jsonEncode(row),
        ));
  }

  /// Insert many rows in one request (used for heart-rate batches).
  Future<void> insertRows(
    String table,
    List<Map<String, dynamic>> rows, {
    required String token,
  }) async {
    if (rows.isEmpty) return;
    await _send(() => _client.post(
          _restUri('/$table'),
          headers: {..._userHeaders(token), 'Prefer': 'return=minimal'},
          body: jsonEncode(rows),
        ));
  }

  /// PATCH rows matching [filter], e.g. "id=eq.<uid>".
  Future<void> update(
    String table, {
    required String filter,
    required Map<String, dynamic> row,
    required String token,
  }) async {
    await _send(() => _client.patch(
          _restUri('/$table?$filter'),
          headers: {..._userHeaders(token), 'Prefer': 'return=minimal'},
          body: jsonEncode(row),
        ));
  }
}
