#!/bin/bash
set -e

echo "📦 Configurando Flutter SDK..."

# Debug: Verificar variáveis de ambiente
echo "🔍 Verificando variáveis de ambiente..."
if [ -z "$SUPABASE_URL" ]; then
  echo "❌ ERRO: SUPABASE_URL não está definida!"
  exit 1
fi
if [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "❌ ERRO: SUPABASE_ANON_KEY não está definida!"
  exit 1
fi

echo "✅ SUPABASE_URL: ${SUPABASE_URL:0:30}..."
echo "✅ SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY:0:20}..."
echo "✅ PRODUCTION: $PRODUCTION"

# 1. Baixar ou atualizar Flutter (usando branch stable para evitar erros de versão)
if [ ! -d "flutter" ]; then
  echo "⬇️ Clonando Flutter SDK (branch stable)..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
else
  echo "🔄 Atualizando Flutter SDK..."
  cd flutter && git pull origin stable && cd ..
fi

# 2. Adicionar ao PATH
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Configuração inicial
echo "🛠️ Inicializando Flutter..."
flutter config --enable-web
flutter doctor > /dev/null 2>&1

# 4. Instalar Dependências
echo "📦 Instalando dependências..."
flutter pub get

# 5. Build de Produção
echo "🔨 Gerando build de produção..."
flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=PRODUCTION=true

echo "✅ Build concluído com sucesso!"
