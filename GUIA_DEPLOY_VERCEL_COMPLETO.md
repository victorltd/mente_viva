# 🚀 Guia Completo: Deploy do MenteViva no Vercel

## 📋 O Que é o Vercel?

O Vercel é uma plataforma de hospedagem na nuvem que facilita o deploy de aplicações web. É **gratuito** para projetos pessoais e muito fácil de usar.

---

## 🎯 Passo a Passo Completo

### PASSO 1: Criar Conta no Vercel

1. Acesse **https://vercel.com**
2. Clique em **"Sign Up"** (canto superior direito)
3. Escolha uma das opções:
   - **Continue with GitHub** (recomendado - usa sua conta GitHub)
   - Continue with Google
   - Continue with Email
4. Se usar GitHub, autorize o acesso ao seu repositório
5. Pronto! Sua conta está criada ✅

---

### PASSO 2: Preparar o Repositório no GitHub

Se seu projeto **JÁ ESTÁ** no GitHub, pule para o Passo 3.

Se **NÃO ESTÁ**, siga:

#### 2.1: Criar Repositório no GitHub

1. Acesse **https://github.com**
2. Faça login
3. Clique no botão verde **"New"** (ou "+" no canto superior direito → "New repository")
4. Preencha:
   - **Repository name**: `menteviva` (ou o nome que preferir)
   - **Description**: `MenteViva - App de saúde mental`
   - Marque **Private** ou **Public** (sua escolha)
   - **NÃO** marque "Initialize with README" (seu projeto já tem arquivos)
5. Clique em **"Create repository"**

#### 2.2: Conectar seu Projeto Local ao GitHub

No terminal (dentro da pasta do projeto):

```bash
# Inicializar git (se ainda não fez)
git init

# Adicionar todos os arquivos
git add .

# Fazer primeiro commit
git commit -m "Primeiro commit - MenteViva pronto para produção"

# Conectar ao repositório remoto (substitua SEU_USUARIO pelo seu usuário do GitHub)
git remote add origin https://github.com/SEU_USUARIO/menteviva.git

# Enviar para o GitHub
git branch -M main
git push -u origin main
```

**Se der erro de autenticação**, use:
```bash
# Para Windows (se tiver Git Credential Manager)
git push -u origin main

# Ou use o GitHub CLI (se instalado):
gh auth login
gh repo push origin main
```

---

### PASSO 3: Acessar o Dashboard do Vercel

1. Acesse **https://vercel.com/dashboard**
2. Faça login (se não estiver logado)
3. Clique no botão **"Add New..."** → **"Project"**

---

### PASSO 4: Importar o Repositório

1. Na tela "Import Git Repository", você verá uma lista dos seus repositórios do GitHub
2. Encontre **`menteviva`** e clique em **"Import"** ao lado
3. Se não aparecer, clique em **"Adjust GitHub App Permissions →"** e siga as instruções

---

### PASSO 5: Configurar o Projeto

Você verá uma tela de configuração. Preencha assim:

#### 5.1: Project Name
- Deixe como está (geralmente `menteviva`)

#### 5.2: Framework Preset
- Deixe **"Other"** (Flutter não está na lista)

#### 5.3: Build and Output Settings

Esta é a parte **MAIS IMPORTANTE**! Clique em **"Edit"** ao lado de cada campo:

| Campo | Valor |
|-------|-------|
| **Build Command** | `if cd flutter; then git pull && cd .. ; else git clone https://github.com/flutter/flutter.git; fi && flutter/bin/flutter config --enable-web && flutter/bin/flutter build web --release --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY --dart-define=PRODUCTION=true` |
| **Output Directory** | `build/web` |
| **Install Command** | `if cd flutter; then git pull && cd .. ; else git clone https://github.com/flutter/flutter.git; fi && flutter/bin/flutter doctor` |

**Como editar:**
1. Clique em **"Edit"** ao lado de "Build Command"
2. Copie e cole o valor exato da tabela acima
3. Clique em **"Save"**
4. Repita para "Output Directory" e "Install Command"

---

### PASSO 6: Adicionar Variáveis de Ambiente

**ESTA É A PARTE MAIS CRÍTICA!** Sem isso, o app não conecta ao Supabase.

1. Na mesma tela, clique em **"Environment Variables"** (seção abaixo)
2. Clique em **"Add"** para adicionar cada variável:

#### Variável 1: SUPABASE_URL
- **Name**: `SUPABASE_URL`
- **Value**: `https://ileemjyjaffydehqsbyg.supabase.co`
- Marque todas as opções: **Production**, **Preview**, **Development**
- Clique em **"Save"**

#### Variável 2: SUPABASE_ANON_KEY
- **Name**: `SUPABASE_ANON_KEY`
- **Value**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlsZWVtanlqYWZmeWRlaHFzYnlnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2NDUwMDMsImV4cCI6MjA5MDIyMTAwM30.PgaADGYcI5qXc_feUyEeo9hoFYbggHKqjEZRctoOmfs`
- Marque todas as opções: **Production**, **Preview**, **Development**
- Clique em **"Save"**

#### Variável 3: PRODUCTION
- **Name**: `PRODUCTION`
- **Value**: `true`
- Marque todas as opções: **Production**, **Preview**, **Development**
- Clique em **"Save"**

**Verifique se todas as 3 variáveis estão listadas antes de continuar!**

---

### PASSO 7: Fazer o Deploy!

1. Clique no botão azul **"Deploy"** (canto inferior direito)
2. Aguarde o build (pode levar **3-5 minutos** na primeira vez)
3. Você verá o progresso em tempo real

#### O Que Acontece Durante o Build:
- ✅ Clonando Flutter SDK (~1 min)
- ✅ Instalando dependências (~30 seg)
- ✅ Build do app (~1-2 min)
- ✅ Deploy (~30 seg)

---

### PASSO 8: Acessar o App

1. Quando o deploy concluir, você verá uma tela de **"Congratulations!"**
2. Clique em **"Visit"** para abrir o app
3. A URL será algo como: `https://menteviva-xxxx.vercel.app`

**Esta é a URL do seu app!** Você pode compartilhar com quem quiser.

---

## ✅ Verificando o Deploy

### Teste 1: App Carrega
1. Abra a URL no navegador
2. Você deve ver a tela de **login do MenteViva**
3. **Não aparece** erros de conexão

### Teste 2: Sem Logs Sensíveis
1. Abra o **Console do Navegador** (F12)
2. Faça login
3. **NÃO deve aparecer**: `GoRouter: INFO: going to /login`
4. **DEVE aparecer**: `🚀 Iniciando MenteViva...`

### Teste 3: Funcionalidades Básicas
1. Faça login com sua conta
2. Navegue entre telas
3. Verifique que tudo funciona normalmente

---

## 🔧 Configurando Domínio Customizado (Opcional)

Se você tem um domínio próprio (ex: `menteviva.com.br`):

1. No dashboard do Vercel, vá em **"Settings"** → **"Domains"**
2. Digite seu domínio (ex: `menteviva.com.br`)
3. Clique em **"Add"**
4. O Vercel mostrará os registros DNS para configurar:
   - **Type**: `CNAME`
   - **Name**: `@` ou `www`
   - **Value**: `cname.vercel-dns.com`
5. Configure no seu provedor de domínio (Registro.br, GoDaddy, etc.)
6. Aguarde propagação (pode levar até 48h)

---

## 🔄 Fazendo Atualizações (Deploy Automático)

Sempre que você fizer push para o GitHub, o Vercel faz deploy **automaticamente**!

```bash
# Após fazer alterações:
git add .
git commit -m "Minha alteração"
git push origin main
```

O Vercel vai:
1. Detectar o push
2. Fazer build automaticamente
3. Deployar a nova versão
4. Manter a versão anterior como backup

---

## 🐛 Troubleshooting

### PROBLEMA 1: Build Falha

**Causa:** Variáveis de ambiente não configuradas

**Solução:**
1. Vá em **Settings** → **Environment Variables**
2. Verifique se as 3 variáveis estão presentes
3. Clique em **"Redeploy"** (aba "Deployments")

---

### PROBLEMA 2: App Não Conecta ao Supabase

**Causa:** SUPABASE_URL ou SUPABASE_ANON_KEY incorretas

**Solução:**
1. Verifique as variáveis de ambiente no dashboard
2. Copie exatamente os valores do seu projeto Supabase
3. Faça **Redeploy**

---

### PROBLEMA 3: Erro 404 ao Navegar

**Causa:** Configuração de rotas faltando

**Solução:**
1. Verifique se o arquivo `vercel.json` está no repositório
2. Se não estiver, adicione e faça push
3. Faça **Redeploy**

---

### PROBLEMA 4: Build Demora Muito

**Causa:** Primeira vez clonando Flutter SDK

**Solução:**
- Na primeira vez, é **normal** (3-5 min)
- Nas próximas, será mais rápido (~1-2 min)

---

## 📊 Acessando Logs do Deploy

Se algo der errado:

1. No dashboard do Vercel, clique em **"Deployments"**
2. Clique no deploy que falhou
3. Clique em **"Build Logs"** para ver o que aconteceu
4. Procure por mensagens de erro (em vermelho)

---

## 💡 Dicas Importantes

### Segurança
- ✅ **NUNCA** commite a `SUPABASE_ANON_KEY` no código
- ✅ Use **sempre** variáveis de ambiente do Vercel
- ✅ O arquivo `.env` está no `.gitignore` (não será commitado)

### Performance
- ✅ O Vercel usa **CDN global** (seu app será rápido em qualquer lugar)
- ✅ Builds subsequentes são mais rápidos (cache)
- ✅ Use **Lazy Loading** para telas pesadas

### Backup
- ✅ O Vercel mantém **histórico de deploys**
- ✅ Você pode reverter para qualquer versão anterior
- ✅ Vá em **"Deployments"** → Clique nos 3 pontos → **"Rollback"**

---

## 📞 Suporte

Se algo der errado:

1. **Verifique os logs** no dashboard do Vercel
2. **Confira as variáveis** de ambiente
3. **Teste localmente** primeiro:
   ```bash
   flutter run -d chrome
   ```
4. **Consulte a documentação**: https://vercel.com/docs

---

## ✅ Checklist Final

Antes de clicar em "Deploy", verifique:

- [ ] Repositório pushado para GitHub
- [ ] Conta no Vercel criada
- [ ] Projeto importado no Vercel
- [ ] Build Command configurado
- [ ] Output Directory configurado (`build/web`)
- [ ] Install Command configurado
- [ ] SUPABASE_URL adicionada
- [ ] SUPABASE_ANON_KEY adicionada
- [ ] PRODUCTION=true adicionada
- [ ] Arquivo `vercel.json` está no repositório
- [ ] Clicou em "Deploy"

**Se tudo está ✅, seu deploy vai funcionar!** 🚀

---

**Boa sorte com o deploy!** Se precisar de ajuda, consulte os logs no dashboard do Vercel.
