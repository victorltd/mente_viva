// lib/core/supabase/supabase_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/constants/supabase_constants.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConstants.url,
      anonKey: SupabaseConstants.anonKey,
    );
  }

  // ══════════════════════════════════════
  // AUTH HELPERS
  // ══════════════════════════════════════
  static User? get currentUser => client.auth.currentUser;
  static String? get currentUserId => client.auth.currentUser?.id;
  static bool get isAuthenticated => client.auth.currentUser != null;

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  // ══════════════════════════════════════
  // SIGN UP
  // ══════════════════════════════════════
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  // ══════════════════════════════════════
  // SIGN IN
  // ══════════════════════════════════════
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ══════════════════════════════════════
  // SIGN OUT
  // ══════════════════════════════════════
  static Future<void> signOut() async {
    await client.auth.signOut();
  }
}