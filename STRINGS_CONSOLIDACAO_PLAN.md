# 🎯 Plano de Consolidação de Strings

**Status:** ✅ Strings adicionadas a AppStrings  
**Data:** 11 de março de 2026  
**Próximo passo:** Substituir hardcoded strings nos arquivos

---

## ✅ Strings Adicionadas a AppStrings

```
🔹 phoneNumberMinTenDigits
🔹 relatoriosGerenciais
🔹 exportarPdfCompartilhar
🔹 semDadosMes
🔹 metricsTotal
🔹 metricsCompleted
🔹 metricsCanceled
🔹 metricsCancellationRate
🔹 detalhamentoCancelamentos
🔹 tardio
🔹 normal
🔹 gerandoPdf
🔹 relatorioMensalTitulo
🔹 resumoFinanceiro
🔹 detalhamento
🔹 erroGerarPdf(erro)
🔹 recarregar
🔹 configuracoesGerais
🔹 usuariosManutencao
🔹 agendamentosManutencao
🔹 validandoDados
🔹 dadosValidos
🔹 jaPossuiRegistro
🔹 sincronizarDados
🔹 sucessoSincronizacao
🔹 erroSincronizacao(erro)
🔹 senhasMaster
🔹 adicionarSenha
🔹 administracaoAgendamentosCompleto
🔹 procurarAgendamento
```

---

## 📋 Mapa de Substituições por Arquivo

### 1. **signup_view.dart** (CRÍTICO)
**Arquivo:** `lib/features/auth/view/signup_view.dart`  
**Linha:** 335

**Encontrado:**
```dart
Text('$numeroLabel com no mínimo 10 dígitos')
```

**Substituir por:**
```dart
Text('$numeroLabel ${AppStrings.phoneNumberMinTenDigits}')
```

---

### 2. **relatorios_view.dart** (12 strings)
**Arquivo:** `lib/features/admin/view/relatorios_view.dart`

| Linha | Encontrado | Substituir | String |
|-------|-----------|-----------|--------|
| 20 | `const Text('Relatórios Gerenciais')` | `const Text(AppStrings.relatoriosGerenciais)` | `relatoriosGerenciais` |
| 27 | `tooltip: 'Exportar PDF e Compartilhar'` | `tooltip: AppStrings.exportarPdfCompartilhar` | `exportarPdfCompartilhar` |
| 46 | `'Sem dados para este mês.'` | `AppStrings.semDadosMes` | `semDadosMes` |
| 70 | `'Total Agendado'` | `AppStrings.metricsTotal` | `metricsTotal` |
| 71 | `'Realizados/Conf.'` | `AppStrings.metricsCompleted` | `metricsCompleted` |
| 72 | `'Cancelados'` | `AppStrings.metricsCanceled` | `metricsCanceled` |
| 73 | `'Taxa Cancelamento'` | `AppStrings.metricsCancellationRate` | `metricsCancellationRate` |
| 85 | `'Detalhamento de Cancelamentos'` | `AppStrings.detalhamentoCancelamentos` | `detalhamentoCancelamentos` |
| 87 | `'Tardio' / 'Normal'` | `AppStrings.tardio / AppStrings.normal` | `tardio` / `normal` |
| 118 | `SnackBar(content: Text('Gerando PDF...'))` | `SnackBar(content: Text(AppStrings.gerandoPdf))` | `gerandoPdf` |
| 147 | `pw.Text('Relatório Mensal - Agenda Massoterapia', ...)` | `pw.Text(AppStrings.relatorioMensalTitulo, ...)` | `relatorioMensalTitulo` |
| 200 | `'Erro ao gerar PDF: $e'` | `AppStrings.erroGerarPdf(e)` | `erroGerarPdf` |

**Seções em PDF (requer função paramétrica):**
```dart
// Linha 162
pw.Text('Resumo Financeiro', ...) → pw.Text(AppStrings.resumoFinanceiro, ...)

// Linha 173
pw.Text('Detalhamento', ...) → pw.Text(AppStrings.detalhamento, ...)
```

---

### 3. **admin_ferramentas_database_setup_view.dart** (20+ strings)
**Arquivo:** `lib/features/admin/view/admin_ferramentas_database_setup_view.dart`

| Linha | Encontrado | Substituir |
|-------|-----------|-----------|
| 148 | `tooltip: 'Recarregar'` | `tooltip: AppStrings.recarregar` |
| 159-298 | `_buildSecaoTitulo('📋 Configurações Gerais')` | `_buildSecaoTitulo(AppStrings.configuracoesGerais)` |
| (~) | `'👥 Usuários (Manutenção)'` | `AppStrings.usuariosManutencao` |
| (~) | `'📅 Agendamentos (Manutenção)'` | `AppStrings.agendamentosManutencao` |
| (~) | `'Validando dados...'` | `AppStrings.validandoDados` |
| (~) | `'Dados válidos! ✓'` | `AppStrings.dadosValidos` |
| (~) | `'Já possui registro'` | `AppStrings.jaPossuiRegistro` |
| (~) | `'Sincronizar Dados'` | `AppStrings.sincronizarDados` |
| (~) | `'Sincronização realizada!'` | `AppStrings.sucessoSincronizacao` |
| (~) | `'Erro na sincronização: $erro'` | `AppStrings.erroSincronizacao(erro)` |

---

### 4. **admin_ferramentas_senha_setup_view.dart** (1 string)
**Arquivo:** `lib/features/admin/view/admin_ferramentas_senha_setup_view.dart`

| Linha | Encontrado | Substituir |
|-------|-----------|-----------|
| ? | `'Senhas Master'` | `AppStrings.senhasMaster` |

---

### 5. **admin_agendamentos_view.dart** (2 strings)
**Arquivo:** `lib/features/perfil/view/admin_agendamentos_view.dart`

| Linha | Encontrado | Substituir |
|-------|-----------|-----------|
| ? | `'Administração de Agendamentos'` | `AppStrings.administracaoAgendamentosCompleto` |
| ? | `'Procurar agendamento...'` | `AppStrings.procurarAgendamento` |

---

## 🔍 Verificações Recomendadas

### Adicionar Import em Cada Arquivo:
```dart
import 'package:agenda/core/utils/app_strings.dart';
```

### Validar Após Substituição:
```bash
dart analyze lib/
# Verificar erros de compilação
```

---

## 📊 Progresso

| Arquivo | Status | Strings |
|---------|--------|---------|
| AppStrings | ✅ Completado | +30 strings adicionadas |
| signup_view.dart | ⏳ Pendente | 1 substitução |
| relatorios_view.dart | ⏳ Pendente | 12 substituições |
| admin_ferramentas_database_setup_view.dart | ⏳ Pendente | 20+ substituições |
| admin_ferramentas_senha_setup_view.dart | ⏳ Pendente | 1 substitução |
| admin_agendamentos_view.dart | ⏳ Pendente | 2 substituições |

**Total:** 36+ substituições pendentes

---

## 🚀 Próximas Ações

1. ✅ **Strings adicionadas a AppStrings**
2. ⏳ **Substituir em signup_view.dart** (rápido - 1 string)
3. ⏳ **Substituir em relatorios_view.dart** (média - 12 strings)
4. ⏳ **Substituir em admin_ferramentas_database_setup_view.dart** (demorado - 20+ strings)
5. ⏳ **Validar com dart analyze**
6. ⏳ **Testar em runtime**
