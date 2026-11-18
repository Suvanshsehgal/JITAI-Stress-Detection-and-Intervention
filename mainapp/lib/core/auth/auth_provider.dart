import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/shared_prefs_provider.dart';
import '../network/api_client.dart';
import '../supabase/supabase_auth_service.dart';
import 'token_storage.dart';

/// Keys in SharedPreferences that mirror the user's onboarding status on this device.
const String onboardingCompletedKey = 'onboardingCompleted';

class AuthState {
  final bool isAuthenticated;
  final bool isGuest;
  final String? userId;
  final String? email;
  final String? username;
  final String? token;
  final bool isLoading;
  final String? errorMessage;
  final String? infoMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.isGuest = false,
    this.userId,
    this.email,
    this.username,
    this.token,
    this.isLoading = false,
    this.errorMessage,
    this.infoMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isGuest,
    String? userId,
    String? email,
    String? username,
    String? token,
    bool? isLoading,
    String? errorMessage,
    String? infoMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isGuest: isGuest ?? this.isGuest,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      username: username ?? this.username,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearError ? null : (infoMessage ?? this.infoMessage),
    );
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SharedPrefsTokenStorage(prefs);
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final client = ApiClient();
  final token = storage.getToken();
  if (token != null) {
    client.setAuthToken(token);
  }
  return client;
});

/// Plain-HTTP Supabase client (auth + tables). Shared by auth and onboarding.
final supabaseAuthProvider = Provider<SupabaseAuthService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SupabaseAuthService(prefs: prefs);
});

/// Email/password auth against Supabase (Stride Probe project).
class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseAuthService _auth;
  final SharedPreferences _prefs;
  final TokenStorage _tokenStorage;

  AuthNotifier({
    required SupabaseAuthService auth,
    required SharedPreferences prefs,
    required TokenStorage tokenStorage,
  })  : _auth = auth,
        _prefs = prefs,
        _tokenStorage = tokenStorage,
        super(const AuthState()) {
    _restore();
  }

  /// Synchronous from storage so the router sees "signed in" at startup.
  /// The token is refreshed in the background.
  void _restore() {
    final s = _auth.storedSession();
    if (s == null) return;
    state = _signedInState(s);
    unawaited(_refreshInBackground());
  }

  Future<void> _refreshInBackground() async {
    final s = await _auth.currentSession();
    if (s == null) {
      // Refresh token rejected: back to the login screen.
      state = const AuthState();
      return;
    }
    await _syncProfile(s);
  }

  AuthState _signedInState(SupabaseSession s, {String? username}) => AuthState(
        isAuthenticated: true,
        isGuest: false,
        userId: s.userId,
        email: s.email,
        username: username ?? s.username ?? _usernameFromEmail(s.email),
        token: s.accessToken,
      );

  String? _usernameFromEmail(String? email) {
    if (email == null || !email.contains('@')) return null;
    return email.split('@').first;
  }

  /// Loads the profile row and mirrors its onboarding flag on this device.
  /// Best effort: the app still works if this fails (for example, offline).
  Future<void> _syncProfile(SupabaseSession s) async {
    try {
      final token = await _auth.accessToken() ?? s.accessToken;
      final rows = await _auth.select(
        'profiles',
        query: 'select=username,onboarding_completed&id=eq.${s.userId}',
        token: token,
      );
      final row = rows.isEmpty ? null : rows.first;
      await _prefs.setBool(onboardingCompletedKey, row?['onboarding_completed'] == true);
      final name = row?['username'];
      if (name is String && name.isNotEmpty) {
        state = state.copyWith(username: name);
      }
    } catch (_) {
      // Keep whatever we already know.
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final s = await _auth.signInWithPassword(email: email.trim(), password: password);
      await _syncProfile(s);
      await _tokenStorage.saveToken(s.accessToken);
      state = _signedInState(s, username: state.username).copyWith(isLoading: false);
      return true;
    } on SupabaseException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _friendly(e.message));
      return false;
    }
  }

  /// Returns true when the account is ready to use. When email confirmation is
  /// required, returns false and sets [AuthState.infoMessage] instead.
  Future<bool> register({
    required String email,
    required String password,
    required String username,
    required String buddyName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final s = await _auth.signUp(
        email: email.trim(),
        password: password,
        data: {'username': username, 'buddy_name': buddyName},
      );

      if (s == null) {
        state = state.copyWith(
          isLoading: false,
          infoMessage: 'Check your email to confirm your account, then sign in.',
        );
        return false;
      }

      try {
        await _auth.upsert(
          'profiles',
          {'id': s.userId, 'username': username, 'buddy_name': buddyName},
          token: s.accessToken,
        );
      } on SupabaseException catch (e) {
        await _auth.signOut();
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.code == '23505'
              ? 'That username is already taken.'
              : 'Profile could not be saved. Please try again.',
        );
        return false;
      }

      await _prefs.setBool(onboardingCompletedKey, false);
      await _tokenStorage.saveToken(s.accessToken);
      state = _signedInState(s, username: username).copyWith(isLoading: false);
      return true;
    } on SupabaseException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _friendly(e.message));
      return false;
    }
  }

  /// Offline explore mode: no account, nothing is written to Supabase.
  Future<bool> loginGuest() async {
    const token = 'guest_token_offline_v1';
    await _tokenStorage.saveToken(token);
    state = state.copyWith(
      isLoading: false,
      isAuthenticated: true,
      isGuest: true,
      userId: 'guest_user',
      username: 'Guest',
      token: token,
      clearError: true,
    );
    return true;
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _tokenStorage.clearToken();
    state = const AuthState();
  }

  String _friendly(String message) {
    final m = message.toLowerCase();
    if (m.contains('invalid login credentials')) return 'Wrong email or password.';
    if (m.contains('email not confirmed')) return 'Please confirm your email first.';
    if (m.contains('already registered') || m.contains('already been registered') ||
        m.contains('already exists')) {
      return 'An account with this email already exists.';
    }
    if (m.contains('password')) return 'Password must be at least 6 characters.';
    return message;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  final auth = ref.watch(supabaseAuthProvider);
  return AuthNotifier(auth: auth, prefs: prefs, tokenStorage: tokenStorage);
});
