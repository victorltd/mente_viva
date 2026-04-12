// lib/config/env.dart

// ══════════════════════════════════════════════════════════════════════════════
// VARIÁVEIS DE AMBIENTE
// Em produção, essas variáveis são injetadas via --dart-define no build
// Para desenvolvimento local, use valores padrão (não commitar em produção!)
// ══════════════════════════════════════════════════════════════════════════════

class Env {
  // Supabase
  // Em produção: usar --dart-define para sobrescrever
  // Exemplo: flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ileemjyjaffydehqsbyg.supabase.co', // Dev apenas
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlsZWVtanlqYWZmeWRlaHFzYnlnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2NDUwMDMsImV4cCI6MjA5MDIyMTAwM30.PgaADGYcI5qXc_feUyEeo9hoFYbggHKqjEZRctoOmfs', // Dev apenas
  );

  // App
  static const String appName = 'MenteViva';
  static const String appVersion = '1.0.0';

  // Ambiente
  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );

  // Validação em runtime (apenas em produção)
  static void validate() {
    if (isProduction && (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty)) {
      throw Exception(
        'Variáveis de ambiente do Supabase não configuradas!\n'
        'Em produção, use --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
      );
    }
  }
}