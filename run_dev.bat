@echo off
REM Script helper para rodar o app com variaveis de ambiente de desenvolvimento
REM Uso: run_dev.bat

echo ═══════════════════════════════════════════════════════
echo   Iniciando MenteViva em modo desenvolvimento...
echo ═══════════════════════════════════════════════════════

flutter run -d chrome ^
  --dart-define=SUPABASE_URL=https://ileemjyjaffydehqsbyg.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlsZWVtanlqYWZmeWRlaHFzYnlnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2NDUwMDMsImV4cCI6MjA5MDIyMTAwM30.PgaADGYcI5qXc_feUyEeo9hoFYbggHKqjEZRctoOmfs ^
  --dart-define=PRODUCTION=false
