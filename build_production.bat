@echo off
REM ═══════════════════════════════════════════════════════
REM SCRIPT DE BUILD PARA PRODUÇÃO - MenteViva (Windows)
REM ═══════════════════════════════════════════════════════
REM Uso: build_production.bat

echo ════════════════════════════════════════════════════════
echo   MenteViva - Build de Produção
echo ════════════════════════════════════════════════════════
echo.
echo Verificando variaveis de ambiente...

REM Verificar se as variaveis estão definidas
if "%SUPABASE_URL%"=="" (
    echo ERRO: SUPABASE_URL nao definido!
    echo Use: set SUPABASE_URL=https://sua-url.supabase.co
    echo      set SUPABASE_ANON_KEY=sua-chave-aqui
    echo      build_production.bat
    pause
    exit /b 1
)

if "%SUPABASE_ANON_KEY%"=="" (
    echo ERRO: SUPABASE_ANON_KEY nao definido!
    echo Use: set SUPABASE_URL=https://sua-url.supabase.co
    echo      set SUPABASE_ANON_KEY=sua-chave-aqui
    echo      build_production.bat
    pause
    exit /b 1
)

echo.
echo Configurando variaveis...
echo    SUPABASE_URL: %SUPABASE_URL:~0,30%...
echo    PRODUCTION: true
echo.

REM Flutter pub get
echo Instalando dependencias...
call flutter pub get

REM Build
echo.
echo Fazendo build de producao...
call flutter build web ^
  --release ^
  --dart-define=SUPABASE_URL=%SUPABASE_URL% ^
  --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY% ^
  --dart-define=DEMO_PSI_EMAIL=%DEMO_PSI_EMAIL% ^
  --dart-define=DEMO_PSI_PASSWORD=%DEMO_PSI_PASSWORD% ^
  --dart-define=DEMO_PATIENT_EMAIL=%DEMO_PATIENT_EMAIL% ^
  --dart-define=DEMO_PATIENT_PASSWORD=%DEMO_PATIENT_PASSWORD% ^
  --dart-define=PRODUCTION=true

if %errorlevel% neq 0 (
    echo.
    echo ════════════════════════════════════════════════════════
    echo   ERRO: Build falhou!
    echo ════════════════════════════════════════════════════════
    pause
    exit /b 1
)

echo.
echo ════════════════════════════════════════════════════════
echo   BUILD CONCLUÍDO COM SUCESSO!
echo ════════════════════════════════════════════════════════
echo.
echo Arquivos em: build/web/
echo Para deploy no Vercel: vercel deploy --prod
echo.
pause
