import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthService {
  final supabase = SupabaseConfig.client;

  // Sign up with email, password, and display name
  Future<AuthResponse> signUpWithName(
      String email, String password, String name) async {
    return await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );
  }

  // Sign up with email and password (kept for backward compatibility)
  Future<AuthResponse> signUp(String email, String password) async {
    return await supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  // Get display name from user metadata
  String get userName {
    final meta = supabase.auth.currentUser?.userMetadata;
    final name = meta?['full_name'] as String?;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    // Fallback: derive from email
    final email = supabase.auth.currentUser?.email ?? '';
    return email.isNotEmpty ? email.split('@').first.capitalize() : 'User';
  }

  // Sign in with email and password
  Future<AuthResponse> signIn(String email, String password) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // Get current user ID
  String? get userId => supabase.auth.currentUser?.id;

  // Get current user
  User? get currentUser => supabase.auth.currentUser;

  // Check if user is signed in
  bool get isSignedIn => supabase.auth.currentUser != null;

  // Get user email
  String? get userEmail => supabase.auth.currentUser?.email;

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  // Reset password
  Future<void> resetPassword(String email) async {
    await supabase.auth.resetPasswordForEmail(email);
  }

  // Update user password
  Future<UserResponse> updatePassword(String newPassword) async {
    return await supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // Update user email
  Future<UserResponse> updateEmail(String newEmail) async {
    return await supabase.auth.updateUser(
      UserAttributes(email: newEmail),
    );
  }
}

extension _StringExt on String {
  String capitalize() =>
      isEmpty ? this : this[0].toUpperCase() + substring(1);
}
