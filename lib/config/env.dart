// lib/config/env.dart

// ══════════════════════════════════════════════════════════════════════════════
// VARIÁVEIS DE AMBIENTE
// Em produção, essas variáveis vêm do Vercel/sistema
// ══════════════════════════════════════════════════════════════════════════════

class Env {
  // Supabase
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ileemjyjaffydehqsbyg.supabase.co',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlsZWVtanlqYWZmeWRlaHFzYnlnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2NDUwMDMsImV4cCI6MjA5MDIyMTAwM30.PgaADGYcI5qXc_feUyEeo9hoFYbggHKqjEZRctoOmfs',
  );
  
  // App
  static const String appName = 'MenteViva';
  static const String appVersion = '1.0.0';
  
  // Ambiente
  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );
}

//   static const String url = 'https://ileemjyjaffydehqsbyg.supabase.co';
//   static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlsZWVtanlqYWZmeWRlaHFzYnlnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2NDUwMDMsImV4cCI6MjA5MDIyMTAwM30.PgaADGYcI5qXc_feUyEeo9hoFYbggHKqjEZRctoOmfs';
// }