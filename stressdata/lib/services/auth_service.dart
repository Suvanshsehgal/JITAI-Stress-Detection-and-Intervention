import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthService {
  final supabase = SupabaseConfig.client;

  // Sign up with email and password
  Future<AuthResponse> signUp(String email, String password) async {
    return await supabase.auth.signUp(
      email: email,
      password: password,
    );
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