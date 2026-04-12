#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════
# SCRIPT DE BUILD - MenteViva (Vercel)
# ═══════════════════════════════════════════════════════

echo "📦 Configurando Flutter SDK..."

# 1. Baixar ou atualizar Flutter
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1
else
  cd flutter && git pull && cd ..
fi

# 2. Adicionar ao PATH
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Habilitar Web e Instalar Dependências
echo "🌐 Habilitando suporte Web..."
flutter config --enable-web
flutter pub get

# 4. Build de Produção
echo "🔨 Gerando build de produção..."
flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=PRODUCTION=true

echo "✅ Build concluído com sucesso!"
