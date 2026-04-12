// lib/core/supabase/supabase_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/env.dart';

// ══════════════════════════════════════════════════════════════════════════════
// SUPABASE SERVICE
// ══════════════════════════════════════════════════════════════════════════════

class SupabaseService {
  static SupabaseClient? _client;
  
  // ══════════════════════════════════════════════════════════════════════════
  // INICIALIZAÇÃO
  // ══════════════════════════════════════════════════════════════════════════
  
  static Future<void> initialize() async {
    try {
      debugPrint('══════════════════════════════════════════════════════════');
      debugPrint('🔌 Inicializando Supabase...');
      debugPrint('   URL: ${Env.supabaseUrl}');
      debugPrint('   Produção: ${Env.isProduction}');
      debugPrint('══════════════════════════════════════════════════════════');

      await Supabase.initialize(
        url: Env.supabaseUrl,
        anonKey: Env.supabaseAnonKey,
        debug: !Env.isProduction,
      );

      _client = Supabase.instance.client;

      debugPrint('✅ Supabase inicializado com sucesso!');
    } catch (e) {
      debugPrint('❌ Erro ao inicializar Supabase: $e');
      rethrow;
    }
  }
  
  // ══════════════════════════════════════════════════════════════════════════
  // CLIENT
  // ══════════════════════════════════════════════════════════════════════════
  
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase não foi inicializado. Chame SupabaseService.initialize() primeiro.');
    }
    return _client!;
  }
  
  // ══════════════════════════════════════════════════════════════════════════
  // AUTH HELPERS
  // ══════════════════════════════════════════════════════════════════════════
  
  static User? get currentUser => client.auth.currentUser;
  
  static String? get currentUserId => currentUser?.id;
  
  static bool get isAuthenticated => currentUser != null;
  
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}