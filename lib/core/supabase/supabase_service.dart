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
      // Limpar a URL (remover barra no final e espaços)
      final cleanUrl = Env.supabaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
      final cleanKey = Env.supabaseAnonKey.trim();

      debugPrint('══════════════════════════════════════════════════════════');
      debugPrint('🔌 Inicializando Supabase...');
      debugPrint('   URL Original: ${Env.supabaseUrl}');
      debugPrint('   URL Limpa: $cleanUrl');
      debugPrint('   Produção: ${Env.isProduction}');
      debugPrint('══════════════════════════════════════════════════════════');

      await Supabase.initialize(
        url: cleanUrl,
        anonKey: cleanKey,
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