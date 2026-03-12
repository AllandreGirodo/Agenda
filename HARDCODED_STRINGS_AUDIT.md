# 📋 Auditoria de Textos Hardcoded - Flutter (AppStrings)

**Data:** 11 de março de 2026  
**Escopo:** Todas as strings visíveis ao usuário em widgets (Text, SnackBar, AlertDialog, tooltips, validators, labels)  
**Exclusões:** Comentários, nomes de variáveis, route names, debug logs, IDs, dynamic strings sem referência

---

## 📊 Resumo Geral
- **Total de strings encontradas:** 40+
- **Arquivos afetados:** 8 principais
- **Prioridade:** 🔴 Alta (auth, admin, agendamento)

---

## 🔴 PRIORIDADE ALTA - lib/features/auth/

### 1. **signup_view.dart** (Linha 335)
```dart
'$numeroLabel com no mínimo 10 dígitos'
```
- **Tipo:** SnackBar content
- **Contexto:** Validação de telefone  
- **Sugestão de chave:** `signupPhoneMinDigits` ou `phoneNumberMinTenDigits`
- **PT:** Compor com texto paramétrico
- **EN:** "Phone number with minimum 10 digits"

---

## 🔴 PRIORIDADE ALTA - lib/features/admin/

### 2. **relatorios_view.dart** (Linha 20)
```dart
const Text('Relatórios Gerenciais')
```
- **Tipo:** AppBar title
- **Sugestão de chave:** `relatoriosGerenciais`
- **PT:** Relatórios Gerenciais
- **EN:** Management Reports

### 3. **relatorios_view.dart** (Linha 27)
```dart
tooltip: 'Exportar PDF e Compartilhar'
```
- **Tipo:** IconButton tooltip
- **Sugestão de chave:** `exportarPdfCompartilhar`
- **PT:** Exportar PDF e Compartilhar
- **EN:** Export PDF and Share

### 4. **relatorios_view.dart** (Linha 46)
```dart
const Center(child: Text('Sem dados para este mês.'))
```
- **Tipo:** Placeholder text
- **Sugestão de chave:** `semDadosMes`
- **PT:** Sem dados para este mês.
- **EN:** No data for this month.

### 5. **relatorios_view.dart** (Linha 65-75)
```dart
_buildMetricCard('Total Agendado', '$total', Colors.blue)
_buildMetricCard('Realizados/Conf.', '$realizados', Colors.green)
_buildMetricCard('Cancelados', '$cancelados', Colors.red)
_buildMetricCard('Taxa Cancelamento', '${taxaCancelamento.toStringAsFixed(1)}%', Colors.orange)
```
- **Tipo:** Card titles em gráfico
- **Sugestões de chaves:**
  - `metricsTotal` → "Total Agendado"
  - `metricsCompleted` → "Realizados/Confirmados"
  - `metricsCanceled` → "Cancelados"
  - `metricsCancellationRate` → "Taxa de Cancelamento"

### 6. **relatorios_view.dart** (Linha 80)
```dart
const Text('Detalhamento de Cancelamentos', style: TextStyle(...))
```
- **Tipo:** Section title
- **Sugestão de chave:** `detalhamentoCancelamentos`
- **PT:** Detalhamento de Cancelamentos
- **EN:** Cancellation Details

### 7. **relatorios_view.dart** (Linha 87)
```dart
Text(a.status == 'cancelado_tardio' ? 'Tardio' : 'Normal', ...)
```
- **Tipo:** Status badge text
- **Sugestões de chaves:**
  - `tardio` → "Tardio"
  - `normal` → "Normal"

### 8. **relatorios_view.dart** (Linha 118)
```dart
const SnackBar(content: Text('Gerando PDF...'))
```
- **Tipo:** SnackBar content
- **Sugestão de chave:** `gerandoPdf`
- **PT:** Gerando PDF...
- **EN:** Generating PDF...

### 9. **relatorios_view.dart** (Linha 147)
```dart
pw.Text('Relatório Mensal - Agenda Massoterapia', ...)
```
- **Tipo:** PDF document title
- **Sugestão de chave:** `relatorioMensalTitulo`
- **PT:** Relatório Mensal - Agenda Massoterapia
- **EN:** Monthly Report - Massage Therapy Agenda

### 10. **relatorios_view.dart** (Linha 162, 173)
```dart
pw.Text('Resumo Financeiro', ...)
pw.Text('Detalhamento', ...)
```
- **Tipo:** PDF section headers
- **Sugestões de chaves:**
  - `resumoFinanceiro` → "Resumo Financeiro"
  - `detalhamento` → "Detalhamento"

### 11. **relatorios_view.dart** (Linha 178)
```dart
headers: ['Data', 'Cliente', 'Tipo', 'Status', 'Valor']
```
- **Tipo:** Table headers em PDF
- **Sugestões de chaves:** Criar um Map em AppStrings
  - `tableHeaders` com pt/en translations

### 12. **relatorios_view.dart** (Linha 200)
```dart
SnackBar(content: Text('Erro ao gerar PDF: $e'))
```
- **Tipo:** Error SnackBar
- **Sugestão de chave:** `erroGerarPdf(erro)`
- **PT:** Erro ao gerar PDF: {erro}
- **EN:** Error generating PDF: {erro}

---

### 13. **admin_ferramentas_database_setup_view.dart** (Linha 148)
```dart
tooltip: 'Recarregar'
```
- **Tipo:** IconButton tooltip
- **Sugestão de chave:** `recarregar`
- **PT:** Recarregar
- **EN:** Reload

### 14. **admin_ferramentas_database_setup_view.dart** (Linhas 159-298)
🔧 **Section titles com emojis - MUITAS STRINGS:**
```dart
_buildSecaoTitulo('📋 Configurações Gerais')
_buildSecaoTitulo('🔒 Configurações de Segurança')
_buildSecaoTitulo('💆 Configurações de Serviços')
_buildSecaoTitulo('🔔 Configurações de Notificações')
_buildSecaoTitulo('💳 Configurações de Pagamento')
_buildSecaoTitulo('⚙️ Variáveis de Ambiente (.env)')
```
- **Tipo:** Configuration section headers
- **Sugestões de chaves:**
  - `configSectionGeneral` → "Configurações Gerais"
  - `configSectionSecurity` → "Configurações de Segurança"
  - `configSectionServices` → "Configurações de Serviços"
  - `configSectionNotifications` → "Configurações de Notificações"
  - `configSectionPayment` → "Configurações de Pagamento"
  - `configSectionEnvironment` → "Variáveis de Ambiente"

### 15. **admin_ferramentas_database_setup_view.dart** (Linhas 162-286)
🔧 **Field labels - MUITAS STRINGS:**
```dart
'WhatsApp Admin'
'Preço Sessão (R\$)'
'Horas Antecedência Cancelamento'
'Horário Padrão Início'
'Horário Padrão Fim'
'Intervalo Agendamentos (min)'
'Início Sono (hora)'
'Fim Sono (hora)'
'Biometria Ativa'
'Chat Ativo'
'Tentativas Login Máx'
'Tempo Bloqueio (min)'
'Senha Admin Ferramentas'
'Tipos de Massagem'
'Duração Padrão (min)'
'Preço Padrão (R\$)'
'Aceita PIX'
'Aceita Dinheiro'
```
- **Tipo:** Form field labels
- **Sugestões de chaves:**
  - `dbWhatsappAdmin`, `dbSessionPrice`, `dbMinNoticeHours`, etc.
  - ⚠️ **Nota:** Muitas já podem estar em AppStrings com nomes diferentes!

### 16. **admin_ferramentas_database_setup_view.dart** (Linhas 230, 249)
```dart
labelText: 'Senha'
labelText: 'Confirmar Senha'
```
- **Tipo:** TextField labelText
- **Sugestões de chaves:**
  - `senhaLabel` (já em AppStrings!)
  - `confirmeSenha` (já em AppStrings!)

### 17. **admin_ferramentas_database_setup_view.dart** (Linhas 393, 510, 542)
```dart
labelText: '$label (fixo)'
labelText: '$label (fixo)'
labelText: '$chave (ambiente)'
```
- **Tipo:** Dynamic labels com sufixo
- **Sugestão:** Usar parametrização em AppStrings ou template

---

## 🔴 PRIORIDADE ALTA - lib/features/agendamento/

### 18. **admin_agendamentos_view.dart** (Linha 9) [lib/features/perfil/view/]
```dart
AppBar(title: const Text('Administração de Agendamentos'))
body: const Center(child: Text('Tela de Administração'))
```
- **Tipo:** AppBar title + placeholder
- **Sugestões de chaves:**
  - `adminAgendamentosTitle` → "Administração de Agendamentos"
  - `telaAdministracao` → "Tela de Administração"

---

## 🟡 PRIORIDADE MÉDIA - Validators e Dialog Actions

### 19. **perfil_view.dart** (Linhas 205-259)
```dart
AlertDialog( ... ) 
validator: (v) => _validar('nome', v)
validator: (v) => _validar('whatsapp', v)
validator: _validarCpf
validator: _validarCep
```
- **Contexto:** Dialog title/content e campo validators
- ⚠️ **Revisar métodos `_validar()` e `_validarCpf()` para strings hardcoded retornadas**

### 20. **admin_ferramentas_senha_setup_view.dart** (Linhas 219, 230, 249)
```dart
const Text('Nova Senha de Admin', ...)
labelText: 'Senha'
labelText: 'Confirmar Senha'
```
- **Tipo:** Form labels and title
- **Sugestões de chaves:**
  - `novaSenhaAdmin` → "Nova Senha de Admin"
  - `senha` → "Senha"
  - `confirmeSenha` → "Confirmar Senha"

---

## 🟡 PRIORIDADE MÉDIA - Dynamic/Parameterized Strings

### 21. **agendamento_view.dart** (Linha 613)
```dart
SnackBar(content: Text(entrar  // INCOMPLETO - Verificar!
```
- ⚠️ **Ação necessária:** Ler arquivo completo para confirmar

---

## 📋 Checklist de Ação Recomendada

### Próximos Passos por Arquivo:
1. **relatorios_view.dart** ✋ 12 strings
2. **admin_ferramentas_database_setup_view.dart** ✋ 20+ strings
3. **admin_ferramentas_senha_setup_view.dart** ✋ 3 strings
4. **agendamento_view.dart** [admin_agendamentos_view.dart] ✋ 2 strings
5. **perfil_view.dart** ✋ 4 strings (alerts + validators)
6. **signup_view.dart** ✋ 1 string

---

## 🔧 Chaves AppStrings Sugeridas (Novas)

```dart
// GUI Labels & Titles
static String get relatoriosGerenciais => _isPt ? 'Relatórios Gerenciais' : 'Management Reports';
static String get exportarPdfCompartilhar => _isPt ? 'Exportar PDF e Compartilhar' : 'Export PDF and Share';
static String get semDadosMes => _isPt ? 'Sem dados para este mês.' : 'No data for this month.';
static String get detalhamentoCancelamentos => _isPt ? 'Detalhamento de Cancelamentos' : 'Cancellation Details';
static String get tardio => _isPt ? 'Tardio' : 'Late';
static String get normal => _isPt ? 'Normal' : 'Normal';
static String get detalhamento => _isPt ? 'Detalhamento' : 'Details';
static String get recarregar => _isPt ? 'Recarregar' : 'Reload';

// PDF Related
static String get gerandoPdf => _isPt ? 'Gerando PDF...' : 'Generating PDF...';
static String get relatorioMensalTitulo => _isPt ? 'Relatório Mensal - Agenda Massoterapia' : 'Monthly Report - Massage Therapy Agenda';
static String get resumoFinanceiro => _isPt ? 'Resumo Financeiro' : 'Financial Summary';
static String erroGerarPdf(String erro) => _isPt ? 'Erro ao gerar PDF: $erro' : 'Error generating PDF: $erro';

// Config Section Headers
static String get configSectionGeneral => _isPt ? 'Configurações Gerais' : 'General Settings';
static String get configSectionSecurity => _isPt ? 'Configurações de Segurança' : 'Security Settings';
static String get configSectionServices => _isPt ? 'Configurações de Serviços' : 'Service Settings';
static String get configSectionNotifications => _isPt ? 'Configurações de Notificações' : 'Notification Settings';
static String get configSectionPayment => _isPt ? 'Configurações de Pagamento' : 'Payment Settings';
static String get configSectionEnvironment => _isPt ? 'Variáveis de Ambiente' : 'Environment Variables';

// Admin
static String get administracaoAgendamentos => _isPt ? 'Administração de Agendamentos' : 'Appointment Administration';
static String get telaAdministracao => _isPt ? 'Tela de Administração' : 'Administration Screen';
static String get novaSenhaAdmin => _isPt ? 'Nova Senha de Admin' : 'New Admin Password';

// Metrics
static String get metricsTotal => _isPt ? 'Total Agendado' : 'Total Scheduled';
static String get metricsCompleted => _isPt ? 'Realizados/Conf.' : 'Completed/Confirmed';
static String get metricsCanceled => _isPt ? 'Cancelados' : 'Cancelled';
static String get metricsCancellationRate => _isPt ? 'Taxa de Cancelamento' : 'Cancellation Rate';

// Phone Validation
static String get phoneMinTenDigits => _isPt ? 'com no mínimo 10 dígitos' : 'with minimum 10 digits';
```

---

## 🎯 Observações Importantes

1. **Database Setup View:** Contém MUITOS labels que podem estar duplicados em AppStrings (e.g., `configPrecoSessao` já existe)
   - Revisar mapeamento antes de adicionar novos

2. **Validators:** Muitos validadores em `perfil_view.dart` retornam strings hardcoded
   - Procurar por `return 'Campo obrigatório'` etc. em métodos privados

3. **PDF Generation:** Strings em `pw.Text()` precisam ser localizadas também

4. **Emojis em Section Titles:** Decidir se emojis fazem parte da chave ou se são adicionados dinamicamente

5. **Table Headers:** Considerar criar um Map centralizado para headers reutilizáveis

---

## 📊 Estatísticas Resumidas

| Arquivo | Strings | Prioridade | Status |
|---------|---------|-----------|--------|
| relatorios_view.dart | 12 | 🔴 Alta | Pendente |
| admin_ferramentas_database_setup_view.dart | 20+ | 🔴 Alta | Pendente |
| admin_ferramentas_senha_setup_view.dart | 3 | 🔴 Alta | Pendente |
| perfil/admin_agendamentos_view.dart | 2 | 🔴 Alta | Pendente |
| perfil_view.dart | 4 | 🟡 Média | Pendente |
| signup_view.dart | 1 | 🟡 Média | Pendente |
| **TOTAL** | **~42** | - | **0% concluído** |

