# 🚀 Guia de Deploy - MenteViva no Vercel

## Pré-requisitos

1. Conta no Vercel (gratuita)
2. Projeto Flutter configurado
3. Credenciais do Supabase em mãos

---

## Opção 1: Deploy via Vercel CLI (Recomendado)

### Passo 1: Instalar Vercel CLI
```bash
npm i -g vercel
```

### Passo 2: Login no Vercel
```bash
vercel login
```

### Passo 3: Configurar Variáveis de Ambiente
```bash
# No Windows:
set SUPABASE_URL=https://ileemjyjaffydehqsbyg.supabase.co
set SUPABASE_ANON_KEY=sua-chave-aqui

# No Linux/Mac:
export SUPABASE_URL=https://ileemjyjaffydehqsbyg.supabase.co
export SUPABASE_ANON_KEY=sua-chave-aqui
```

### Passo 4: Build de Produção
```bash
# Windows:
build_production.bat

# Linux/Mac:
chmod +x build_production.sh
./build_production.sh
```

### Passo 5: Deploy
```bash
vercel --prod
```

---

## Opção 2: Deploy via Git Integration (Automático)

### Passo 1: Push para GitHub
```bash
git add .
git commit -m "Preparando para produção"
git push origin main
```

### Passo 2: Conectar no Vercel
1. Acesse https://vercel.com
2. Clique em "Add New Project"
3. Selecione seu repositório
4. Configure as variáveis de ambiente:
   - `SUPABASE_URL`: https://ileemjyjaffydehqsbyg.supabase.co
   - `SUPABASE_ANON_KEY`: sua-chave-aqui
   - `PRODUCTION`: true
5. Clique em "Deploy"

---

## Opção 3: Deploy Manual (build/web)

### Passo 1: Build Local
```bash
build_production.bat  # ou ./build_production.sh
```

### Passo 2: Deploy
```bash
cd build/web
vercel --prod
```

---

## Variáveis de Ambiente Necessárias

| Variável | Descrição | Exemplo |
|----------|-----------|---------|
| `SUPABASE_URL` | URL do projeto Supabase | https://xxx.supabase.co |
| `SUPABASE_ANON_KEY` | Chave anônima do Supabase | eyJhbGciOi... |
| `PRODUCTION` | Modo produção | true |

---

## Verificando o Deploy

1. Acesse a URL fornecida pelo Vercel
2. Faça login no app
3. Verifique no console do navegador (F12):
   - ❌ NÃO deve aparecer: `GoRouter: INFO: going to /login`
   - ✅ Deve aparecer: `🚀 Iniciando MenteViva...`

---

## Rollback (se algo der errado)

```bash
# Ver deployments anteriores
vercel ls

# Fazer rollback para um deployment específico
vercel rollback <deployment-url>
```

---

## Troubleshooting

### Build falha no Vercel
- Verifique se o `vercel.json` está correto
- Confira as variáveis de ambiente no dashboard do Vercel
- Veja os logs: `vercel logs <deployment-url>`

### App não conecta ao Supabase
- Verifique se `SUPABASE_URL` e `SUPABASE_ANON_KEY` estão corretas
- No Supabase, verifique se as RLS policies estão configuradas
- Verifique se o projeto Supabase está ativo

### Erro 404 em rotas
- O `vercel.json` já tem rewrites configurados
- Se persistir, verifique se o arquivo foi commitado

---

## Domínio Customizado

1. No dashboard do Vercel, vá em "Settings" → "Domains"
2. Adicione seu domínio (ex: menteviva.com.br)
3. Configure o DNS conforme instruções do Vercel

---

**Status do Deploy:** 🟡 Aguardando execução
