// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../core/supabase/supabase_service.dart';
import '../models/profile_model.dart';

// ══════════════════════════════════════
// AUTH STATE
// ══════════════════════════════════════
@immutable
class AppAuthState {
  final bool isLoading;
  final User? user;
  final ProfileModel? profile;
  final String? error;

  const AppAuthState({
    this.isLoading = false,
    this.user,
    this.profile,
    this.error,
  });

  AppAuthState copyWith({
    bool? isLoading,
    User? user,
    ProfileModel? profile,
    String? error,
    bool clearError = false,
    bool clearUser = false,
    bool clearProfile = false,
  }) {
    return AppAuthState(
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      profile: clearProfile ? null : (profile ?? this.profile),
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isAuthenticated => user != null;
  bool get isPsychologist => profile?.isPsychologist ?? false;
  bool get isPatient => profile?.isPatient ?? false;
  bool get needsOnboarding => !(profile?.onboardingCompleted ?? false);
}

// ══════════════════════════════════════
// AUTH NOTIFIER (usando Notifier do Riverpod 2.0+)
// ══════════════════════════════════════
class AuthNotifier extends Notifier<AppAuthState> {

  @override
  AppAuthState build() {
    _init();
    return const AppAuthState();
  }

  SupabaseClient get _client => SupabaseService.client;

  // ══════════════════════════════════════
  // INIT
  // ══════════════════════════════════════
  Future<void> _init() async {
    final user = _client.auth.currentUser;
    if (user != null) {
      state = state.copyWith(user: user, isLoading: true);
      await _loadProfile();
    }

    _client.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn &&
          data.session?.user != null) {
        state = state.copyWith(user: data.session!.user, isLoading: true);
        await _loadProfile();
      } else if (data.event == AuthChangeEvent.signedOut) {
        state = const AppAuthState();
      }
    });
  }

  // ══════════════════════════════════════
  // CARREGAR PERFIL
  // ══════════════════════════════════════
  Future<void> _loadProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final profile = ProfileModel.fromJson(response);
        state = state.copyWith(
          profile: profile,
          isLoading: false,
          clearError: true,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar perfil: $e',
      );
    }
  }

  // ══════════════════════════════════════
  // REGISTRO
  // ══════════════════════════════════════
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role,
        },
      );

      if (response.user != null) {
        state = state.copyWith(
          user: response.user,
          isLoading: false,
        );
        await _loadProfile();
        return true;
      }

      state = state.copyWith(isLoading: false);
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _translateAuthError(e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro inesperado. Tente novamente.',
      );
      return false;
    }
  }

  // ══════════════════════════════════════
  // LOGIN
  // ══════════════════════════════════════
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        state = state.copyWith(
          user: response.user,
          isLoading: false,
        );
        await _loadProfile();
        return true;
      }

      state = state.copyWith(isLoading: false);
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _translateAuthError(e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro inesperado. Tente novamente.',
      );
      return false;
    }
  }

  // ══════════════════════════════════════
  // LOGOUT
  // ══════════════════════════════════════
  Future<void> signOut() async {
    await _client.auth.signOut();
    state = const AppAuthState();
  }

  // ══════════════════════════════════════
  // ATUALIZAR PERFIL
  // ══════════════════════════════════════
  Future<void> updateProfile({
    String? fullName,
    bool? onboardingCompleted,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (onboardingCompleted != null) {
        updates['onboarding_completed'] = onboardingCompleted;
      }

      await _client.from('profiles').update(updates).eq('id', userId);
      await _loadProfile();
    } catch (e) {
      state = state.copyWith(error: 'Erro ao atualizar perfil: $e');
    }
  }

  // ══════════════════════════════════════
  // TRADUZIR ERROS
  // ══════════════════════════════════════
  String _translateAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Email ou senha incorretos';
    }
    if (message.contains('User already registered')) {
      return 'Este email já está cadastrado';
    }
    if (message.contains('Password should be at least')) {
      return 'A senha deve ter pelo menos 6 caracteres';
    }
    if (message.contains('Invalid email')) {
      return 'Email inválido';
    }
    return 'Erro: $message';
  }
}

// ══════════════════════════════════════
// PROVIDER (Riverpod 2.0+ syntax)
// ══════════════════════════════════════
final authProvider =
    NotifierProvider<AuthNotifier, AppAuthState>(AuthNotifier.new);