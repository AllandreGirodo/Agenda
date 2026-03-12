# 📌 Sumário Executivo - Hardcoded Strings Flutter

## 🎯 Localização Rápida

### 1️⃣ lib/features/admin/view/relatorios_view.dart
**12 strings hardcoded | 🔴 ALTA PRIORIDADE**

| Linha | Tipo | Texto | Chave Proposta | PT | EN |
|------|------|-------|-----------------|----|----|
| 20 | AppBar.title | `'Relatórios Gerenciais'` | `relatoriosGerenciais` | Relatórios Gerenciais | Management Reports |
| 27 | tooltip | `'Exportar PDF e Compartilhar'` | `exportarPdfCompartilhar` | Exportar PDF e Compartilhar | Export PDF and Share |
| 46 | Text | `'Sem dados para este mês.'` | `semDadosMes` | Sem dados para este mês. | No data for this month. |
| 65 | Card title | `'Total Agendado'` | `metricsTotal` | Total Agendado | Total Scheduled |
| 67 | Card title | `'Realizados/Conf.'` | `metricsCompleted` | Realizados/Confirmados | Completed/Confirmed |
| 73 | Card title | `'Cancelados'` | `metricsCanceled` | Cancelados | Cancelled |
| 75 | Card title | `'Taxa Cancelamento'` | `metricsCancellationRate` | Taxa de Cancelamento | Cancellation Rate |
| 80 | Text | `'Detalhamento de Cancelamentos'` | `detalhamentoCancelamentos` | Detalhamento de Cancelamentos | Cancellation Details |
| 87 | Badge | `'Tardio'` / `'Normal'` | `tardio` / `normal` | Tardio / Normal | Late / Normal |
| 118 | SnackBar | `'Gerando PDF...'` | `gerandoPdf` | Gerando PDF... | Generating PDF... |
| 147 | pw.Text | `'Relatório Mensal - Agenda Massoterapia'` | `relatorioMensalTitulo` | Relatório Mensal - Agenda Massoterapia | Monthly Report - Massage Therapy Agenda |
| 162, 173 | pw.Text | `'Resumo Financeiro'`, `'Detalhamento'` | `resumoFinanceiro`, `detalhamento` | Resumo Financeiro / Detalhamento | Financial Summary / Details |
| 200 | SnackBar | `'Erro ao gerar PDF: $e'` | `erroGerarPdf(erro)` | Erro ao gerar PDF: {erro} | Error generating PDF: {erro} |

**Ação:** Substituir todas por `AppStrings.{chave}`

---

### 2️⃣ lib/features/admin/view/admin_ferramentas_database_setup_view.dart
**20+ strings hardcoded | 🔴 ALTA PRIORIDADE**

#### A) Section Titles (6 strings)
| Linha | Tipo | Texto | Chave Proposta |
|------|------|-------|-----------------|
| 159 | Section | `'📋 Configurações Gerais'` | `configSectionGeneral` |
| 217 | Section | `'🔒 Configurações de Segurança'` | `configSectionSecurity` |
| 236 | Section | `'💆 Configurações de Serviços'` | `configSectionServices` |
| 255 | Section | `'🔔 Configurações de Notificações'` | `configSectionNotifications` |
| 274 | Section | `'💳 Configurações de Pagamento'` | `configSectionPayment` |
| 298 | Section | `'⚙️ Variáveis de Ambiente (.env)'` | `configSectionEnvironment` |

#### B) Field Labels (15+ strings)
| Campo | Chave Proposta | Status |
|-------|---------------|-----------------------|
| WhatsApp Admin | **JÁ EM AppStrings** (variável diferente) | ✓ Revisar |
| Preço Sessão | `configPrecoSessao` | ⚠️ Verificar duplicação |
| Horas Antecedência Cancelamento | `configAntecedencia` | ⚠️ Verificar duplicação |
| ... (15+ mais) | Ver no arquivo completo | 🔄 Em desenvolvimento |

#### C) UI Components (tooltips, etc.)
| Linha | Tipo | Texto | Chave |
|------|------|-------|-------|
| 148 | tooltip | `'Recarregar'` | `recarregar` |

**Status:** ⚠️ **REVISÃO NECESSÁRIA** - Muitos campos podem estar duplicados em AppStrings com nomes diferentes

---

### 3️⃣ lib/features/admin/view/admin_ferramentas_senha_setup_view.dart
**3 strings hardcoded | 🔴 ALTA PRIORIDADE**

| Linha | Tipo | Texto | Chave Proposta | Status |
|------|------|-------|-----------------|--------|
| 219 | Text | `'Nova Senha de Admin'` | `novaSenhaAdmin` | Novo |
| 230 | labelText | `'Senha'` | `senhaLabel` | ✓ **JÁ EM AppStrings** |
| 249 | labelText | `'Confirmar Senha'` | `confirmeSenha` | ✓ **JÁ EM AppStrings** |

**Ação:** Apenas linha 219 precisa de nova chave

---

### 4️⃣ lib/features/perfil/view/admin_agendamentos_view.dart
**2 strings hardcoded | 🔴 ALTA PRIORIDADE**

| Linha | Tipo | Texto | Chave Proposta | Status |
|------|------|-------|-----------------|--------|
| 9 | AppBar | `'Administração de Agendamentos'` | `administracaoAgendamentos` | Novo |
| 10 | Center | `'Tela de Administração'` | `telaAdministracao` | Novo |

---

### 5️⃣ lib/features/auth/view/signup_view.dart
**1 string hardcoded | 🟡 MÉDIA PRIORIDADE**

| Linha | Tipo | Texto | Chave Proposta | Nota |
|------|------|-------|-----------------|------|
| 335 | SnackBar | `'$numeroLabel com no mínimo 10 dígitos'` | `phoneMinDigitError` | Parametrizado (usar `numeroLabel`) |

---

### 6️⃣ lib/features/perfil/view/perfil_view.dart
**4+ strings em validadores | 🟡 MÉDIA PRIORIDADE**

| Tipo | Contexto | Ação Necessária |
|------|----------|-----------------|
| AlertDialog | Confirmação de exclusão | Revisar título/conteúdo |
| validators | Métodos `_validar()`, `_validarCpf()` | **REVISAR RETORNA STRINGS** |
| tooltip | Labels | Usar AppStrings |

**⚠️ Ação:** Ler métodos de validação para encontrar hardcoded error messages

---

### 7️⃣ lib/features/agendamento/view/agendamento_view.dart (agendamento)
**Possível incompleta (linha 613)**

| Linha | Tipo | Texto | Status |
|------|------|-------|--------|
| 613 | SnackBar | `entrar` (INCOMPLETO) | 🔴 **INVESTIGAR** |

---

## 📊 Métricas Consolidadas

```
TOTAL DE STRINGS ENCONTRADAS: 42+
├── 🔴 Prioridade ALTA: 35+ strings
│   ├── relatorios_view.dart: 12
│   ├── admin_ferramentas_database_setup_view.dart: 20+
│   ├── admin_ferramentas_senha_setup_view.dart: 3
│   ├── perfil/admin_agendamentos_view.dart: 2
│   └── signup_view.dart: 1
├── 🟡 Prioridade MÉDIA: 7+ strings
│   ├── perfil_view.dart: 4+
│   ├── agendamento_view.dart: 1
│   └── Validators diversos: 2+
└── ⚠️ Requer Investigação: 2+ strings
    └── admin_ferramentas_database_setup_view: Duplicações?
```

---

## 🚀 Plano de Ação

### Fase 1: Mapeamento Completo
- [ ] Confirmar todas as chaves em AppStrings (procurar duplicações)
- [ ] Revisar métodos `_validar()` em perfil_view.dart
- [ ] Confirmar contexto da linha 613 em agendamento_view.dart
- [ ] Mapear emojis em section titles

### Fase 2: Criação de Chaves
- [ ] Adicionar 15+ novas chaves em AppStrings
- [ ] Definir pattern para chave de campo vs. label
- [ ] Considerar chaves parametrizadas

### Fase 3: Migração
- [ ] Começar por relatorios_view.dart (12 strings, independente)
- [ ] Migrar admin_ferramentas_senha_setup_view (apenas 1 string nova)
- [ ] Revisar admin_ferramentas_database_setup_view (possíveis duplicações)
- [ ] Finalizar com perfil e signup

### Fase 4: Validação
- [ ] `flutter analyze` em cada arquivo migrado
- [ ] Teste visual em PT/EN/ES/JA (se aplicável)
- [ ] Commit com mensagem padrão: "i18n: migrate hardcoded strings to AppStrings"

---

## 📝 Template para Migração

```dart
// ANTES:
const Text('Relatórios Gerenciais')

// DEPOIS:
Text(AppStrings.relatoriosGerenciais)

// OU (se dinâmico):
Text(AppStrings.erroGerarPdf('$erro'))
```

---

## 🔗 Referências Úteis
- AppStrings: [lib/core/utils/app_strings.dart](lib/core/utils/app_strings.dart)
- AppLocalizations: [lib/app_localizations.dart](lib/app_localizations.dart)
- LanguageSelector: [lib/core/widgets/language_selector.dart](lib/core/widgets/language_selector.dart)

---

**Última atualização:** 11/03/2026  
**Status:** ✋ Aguardando implementação
