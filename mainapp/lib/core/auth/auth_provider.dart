import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shared_prefs_provider.dart';
import '../network/api_client.dart';
import 'token_storage.dart';

class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? username;
  final String? token;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.username,
    this.token,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? username,
    String? token,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
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

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthNotifier({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage,
        super(const AuthState()) {
    _initFromStorage();
  }

  void _initFromStorage() {
    final token = _tokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      _apiClient.setAuthToken(token);
      state = state.copyWith(
        isAuthenticated: true,
        token: token,
      );
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _apiClient.post('/api/v1/auth/login', {
        'username': username,
        'password': password,
      });

      final token = res['access_token'] as String;
      final userId = res['user_id'] as String;
      final uname = res['username'] as String;

      await _tokenStorage.saveToken(token);
      _apiClient.setAuthToken(token);

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        userId: userId,
        username: uname,
        token: token,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is ApiException ? e.message : 'Login failed',
      );
      return false;
    }
  }

  Future<bool> register(String username, String password, {String? buddyName}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _apiClient.post('/api/v1/auth/register', {
        'username': username,
        'password': password,
        'buddy_name': buddyName ?? 'Pip',
      });

      final token = res['access_token'] as String;
      final userId = res['user_id'] as String;
      final uname = res['username'] as String;

      await _tokenStorage.saveToken(token);
      _apiClient.setAuthToken(token);

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        userId: userId,
        username: uname,
        token: token,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is ApiException ? e.message : 'Registration failed',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clearToken();
    _apiClient.setAuthToken(null);
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthNotifier(
    apiClient: apiClient,
    tokenStorage: tokenStorage,
  );
});
