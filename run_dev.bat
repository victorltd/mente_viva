@echo off
REM Script helper para rodar o app com variaveis de ambiente de desenvolvimento
REM Uso: run_dev.bat
REM
REM IMPORTANTE: Preencha os emails e senhas das contas demo abaixo
REM As contas devem existir no Supabase (auth + profiles + dados ficticios)

echo ═══════════════════════════════════════════════════════
echo   Iniciando MenteViva em modo desenvolvimento...
echo ═══════════════════════════════════════════════════════

flutter run -d chrome ^
  --dart-define=SUPABASE_URL=https://ileemjyjaffydehqsbyg.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlsZWVtanlqYWZmeWRlaHFzYnlnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2NDUwMDMsImV4cCI6MjA5MDIyMTAwM30.PgaADGYcI5qXc_feUyEeo9hoFYbggHKqjEZRctoOmfs ^
  --dart-define=PRODUCTION=false ^
  --dart-define=DEMO_PSI_EMAIL=demo_psi@menteviva.app ^
  --dart-define=DEMO_PSI_PASSWORD=senha1234 ^
  --dart-define=DEMO_PATIENT_EMAIL=demo_paciente@menteviva.app ^
  --dart-define=DEMO_PATIENT_PASSWORD=senha1234
