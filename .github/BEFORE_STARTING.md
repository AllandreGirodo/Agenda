# 🚀 ANTES DE COMEÇAR

Se você **clonou este repositório**, siga este checklist **antes de fazer qualquer coisa**.

## ✅ paso a Paso - Configuração Inicial

### 1️⃣ Configure os GitHub Secrets

**⚠️ CRÍTICO:** O CI/CD deste projeto depende de GitHub Secrets para funcionar.

- 📋 Guia detalhado: [`.github/SECRETS_SETUP.md`](.github/SECRETS_SETUP.md)
- ⚡ Checklist rápido: [`.github/SECRETS_QUICK_SETUP.md`](.github/SECRETS_QUICK_SETUP.md) (recomendado)

**Resumo:**
1. Acesse seu repositório no GitHub
2. Vá para **Settings > Secrets and variables > Actions**
3. Cadastre cada secret da [lista de checklist](.github/SECRETS_QUICK_SETUP.md)
4. ✅ Pronto! Agora os workflows funcionarão

**Tempo:** ~20 minutos

---

### 2️⃣ Configure o Arquivo Local .env

Crie um arquivo `.env` na raiz do projeto (use como template):

```bash
cp .env.example .env
```

Ou configure manualmente com seus valores locais (veja `.env.example`).

**Nota:** O arquivo `.env` é ignorado no Git — use-o apenas localmente.

---

### 3️⃣ Instale as Dependências

```bash
flutter pub get
```

---

### 4️⃣ Teste o Projeto

```bash
flutter run
```

---

### 5️⃣ (Web Debug) Configure App Check Debug Token

Se você for rodar no Chrome com Firebase online, configure o token de debug do App Check para evitar erro 403.

1. Rode uma vez para gerar/logar o token:

```bash
flutter run -d chrome --dart-define=ENV=dev
```

2. Copie o valor mostrado no log:

```text
App Check debug token: <SEU_TOKEN>
```

3. No Firebase Console, acesse:

`Build > App Check > Apps > [seu app web] > Gerenciar tokens de depuração > Adicionar token`

4. Preencha:
- Nome: por exemplo `web-chrome-dev-agenda`
- Valor: cole o token do log

5. Rode com App Check habilitado no debug:

```bash
flutter run -d chrome --dart-define=ENV=dev --dart-define=ENABLE_APPCHECK_IN_DEBUG=true --dart-define=FIREBASE_APPCHECK_DEBUG_TOKEN=<SEU_TOKEN>
```

**Cuidado:** o valor do token pode não aparecer novamente no Console. Guarde com segurança e não compartilhe publicamente.

---

## 🔐 Segurança

- ✅ O arquivo `.env` (local) está no `.gitignore`
- ✅ Valores reais de CI ficam em **GitHub Secrets**
- ✅ Segredos de backend devem ficar em backend/Cloud Functions/secret manager
- ✅ Credenciais do Firebase (`.json`) estão no `.gitignore`

**Nunca commite:** `.env`, `serviceAccountKey.json`, ou qualquer arquivo com credenciais reais.

---

## 📚 Documentação Adicional

- **Variáveis de ambiente:** [`.env.example`](.env.example)
- **Secrets do GitHub:** [`.github/SECRETS_SETUP.md`](.github/SECRETS_SETUP.md)
- **Setup Rápido:** [`.github/SECRETS_QUICK_SETUP.md`](.github/SECRETS_QUICK_SETUP.md)

---

## ❓ Problemas Comuns

### ❌ "Testes falhando sem motivo aparente"
→ Você cadastrou os GitHub Secrets? Veja [SECRETS_QUICK_SETUP.md](.github/SECRETS_QUICK_SETUP.md)

### ❌ "CI/CD não roda"
→ Verifique se todos os secrets da checklist atual estão cadastrados em **Settings > Secrets and variables > Actions**

### ❌ ".env: arquivo não encontrado"
→ Execute: `cp .env.example .env`

### ❌ "App Check 403 (exchangeDebugToken)"
→ Verifique se o token de debug foi criado no Firebase Console e se você está rodando com:
`--dart-define=ENABLE_APPCHECK_IN_DEBUG=true --dart-define=FIREBASE_APPCHECK_DEBUG_TOKEN=<SEU_TOKEN>`

---

## ✨ Próximo Passo

Após fazer este setup inicial, você pode:
- Rodar o app localmente: `flutter run`
- Rodar testes: `flutter test`
- Fazer deploy via GitHub Actions (automático em push para `main`)

**Boa sorte! 🎉**
