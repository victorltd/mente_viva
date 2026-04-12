#!/bin/bash
# ═══════════════════════════════════════════════════════
# SCRIPT DE BUILD PARA PRODUÇÃO - MenteViva
# ═══════════════════════════════════════════════════════
# Uso: 
#   ./build_production.sh (com variáveis de ambiente)
#   SUPABASE_URL=xxx SUPABASE_ANON_KEY=xxx ./build_production.sh
# ═══════════════════════════════════════════════════════

# Verificar se as variáveis estão definidas
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "❌ Erro: Variáveis de ambiente não definidas!"
  echo "Use:"
  echo "  export SUPABASE_URL=https://sua-url.supabase.co"
  echo "  export SUPABASE_ANON_KEY=sua-chave-aqui"
  echo "  ./build_production.sh"
  exit 1
fi

echo "═══════════════════════════════════════════════════════"
echo "  MenteViva - Build de Produção"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "📦 Configurando variáveis..."
echo "   SUPABASE_URL: ${SUPABASE_URL:0:30}..."
echo "   PRODUCTION: true"
echo ""

# Flutter pub get
echo "📦 Instalando dependências..."
flutter pub get

# Build
echo "🔨 Fazendo build de produção..."
flutter build web \
  --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=PRODUCTION=true

if [ $? -eq 0 ]; then
  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "  ✅ Build concluído com sucesso!"
  echo "═══════════════════════════════════════════════════════"
  echo ""
  echo "📁 Arquivos em: build/web/"
  echo "🚀 Para deploy no Vercel:"
  echo "   vercel deploy --prod"
  echo ""
else
  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "  ❌ Build falhou!"
  echo "═══════════════════════════════════════════════════════"
  exit 1
fi
