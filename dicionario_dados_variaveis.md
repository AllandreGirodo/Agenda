# Dicionário de Dados e Padronização de Variáveis

Este documento serve como guia de referência para a nomenclatura de variáveis e campos no banco de dados (Firestore), visando integridade referencial e preparação para módulos financeiros.

## 1. Padrões Adotados

*   **IDs e Chaves:**
    *   `uid`: Usado para usuários autenticados (Auth).
    *   `_id`: Sufixo para referências a outros documentos (ex: `cliente_id`, `pagamento_id`).
*   **Datas e Horas:**
    *   `data_`: Prefixo para campos de data (ex: `data_nascimento`).
    *   `_at`: Sufixo para carimbos de tempo de sistema (ex: `created_at`, `updated_at` ou `data_criacao`).
*   **Booleanos:**
    *   `is_` ou `tem_`: Indicadores de estado (ex: `is_ativo`, `tem_anamnese`).

---

## 2. Checklist de Variáveis Atuais vs. Refatoração Sugerida

### Coleção: `agendamentos`
| Variável Dart | Campo Firestore Atual | Sugestão de Melhoria (Profissional) | Motivo |
| :--- | :--- | :--- | :--- |
| `id` | (Auto-ID do Doc) | `agendamento_id` | Clareza ao exportar dados. |
| `clienteId` | `cliente_id` | `cliente_uid` | Diferenciar ID numérico de UID string. |
| `dataHora` | `data_hora` | `data_hora_agendamento` | Evitar ambiguidade com data de criação. |
| `status` | `status` | `status_atual` | Permitir histórico de status futuro. |
| (Inexistente) | (Inexistente) | `cliente_nome_snapshot` | **CRÍTICO:** Manter nome histórico se cliente for excluído. |
| (Inexistente) | (Inexistente) | `valor_sessao_snapshot` | **FINANCEIRO:** O preço pode mudar, o histórico não. |
| (Inexistente) | (Inexistente) | `data_criacao` | Auditoria (quem criou e quando). |

### Perfil do cliente: `usuarios/{email_normalizado}/perfil/cliente`
| Variável Dart | Campo Firestore Atual | Sugestão de Melhoria | Motivo |
| :--- | :--- | :--- | :--- |
| `idCliente` | `uid` | `uid` | Mantido para compatibilidade com Auth e relacoes em agendamentos. |
| `nomeCliente` | `cliente_nome` | `cliente_nome` | Nome civil/principal do cadastro. |
| `nomePreferidoCliente` | `nome_preferido` | `nome_preferido` | Nome de exibição, apelido ou nome social. |
| `whatsappCliente` | `whatsapp` | `whatsapp` + `telefone_principal` | Compatibilidade com legado e transição para telefone principal explícito. |
| `ddiCliente` | `ddi` | `ddi` | Permite evoluir para outros países sem perder o padrão `+55`. |
| `telefonePrincipalCliente` | `telefone_principal` | `telefone_principal` | Campo principal para busca/CRM. |
| `nomeContatoSecundarioCliente` | `nome_contato_secundario` | `nome_contato_secundario` | Identifica o vínculo do segundo número. |
| `telefoneSecundarioCliente` | `telefone_secundario` | `telefone_secundario` | Número alternativo do cliente ou empresa relacionada. |
| `nomeIndicacaoCliente` | `nome_indicacao` | `nome_indicacao` | Rastreia relacionamento/origem do lead. |
| `telefoneIndicacaoCliente` | `telefone_indicacao` | `telefone_indicacao` | Facilita contato da indicação quando fizer sentido comercial. |
| `categoriaOrigemCliente` | `categoria_origem` | `categoria_origem` | Consolidar `Contato Direto` e `Indicação` vindos da planilha. |
| `cpfCliente` | `cpf` | `cpf` | Corrige ausência de persistência de um campo já presente na UI. |
| `cepCliente` | `cep` | `cep` | Corrige ausência de persistência de um campo já presente na UI. |
| `agendaFixaSemanaCliente` | `agenda_fixa_semana` | `agenda_fixa_semana` | Mapa semanal recorrente, melhor que 7 campos soltos na aplicação. |
| `frequenciaHistoricaAgendaCliente` | `frequencia_historica_agenda` | `frequencia_historica_agenda` | Valor numérico útil para priorização/CRM. |
| `ultimaDataAgendadaCliente` | `ultima_data_agendada` | `ultima_data_agendada` | Snapshot da última presença conhecida. |
| `ultimoHorarioAgendadoCliente` | `ultimo_horario_agendado` | `ultimo_horario_agendado` | Ajuda a sugerir horários recorrentes. |
| `ultimoDiaSemanaAgendadoCliente` | `ultimo_dia_semana_agendado` | `ultimo_dia_semana_agendado` | Melhora filtros operacionais. |
| `sugestaoClienteFixo` | `sugestao_cliente_fixo` | `sugestao_cliente_fixo` | Heurística derivada da agenda histórica. |
| `agendaHistoricoCliente` | `agenda_historico` | `agenda_historico` | Guarda `horarios_recorrentes` e preferências `outro_horario_1..5` sem poluir o topo do documento. |
| `saldoSessoesCliente`| `saldo_sessoes` | `saldo_sessoes` | Mantido por compatibilidade funcional atual. |
| `anamneseOkCliente` | `anamnese_ok` | `anamnese_ok` | Mantido para não quebrar código e regras existentes. |

### Campos admin/import-only em `usuarios/{email_normalizado}/perfil/cliente`

Mesmo morando no documento do cliente, estes campos devem ser tratados como dados de apoio operacional e não como dados livres para edição pelo próprio cliente:

- `categoria_origem`
- `presenca_agenda`
- `frequencia_historica_agenda`
- `ultima_data_agendada`
- `ultimo_horario_agendado`
- `ultimo_dia_semana_agendado`
- `sugestao_cliente_fixo`
- `agenda_fixa_semana`
- `agenda_historico`

### Coleção: `usuarios`

| Variável Dart | Campo Firestore Atual | Sugestão de Melhoria | Motivo |
| :--- | :--- | :--- | :--- |
| `ordemCriacao` | `ordem_criacao` | `ordem_criacao` | Sequencial incremental para ordenacao de cadastro de clientes. |
| `ordemCriacaoEm` | `ordem_criacao_em` | `ordem_criacao_em` | Timestamp do cadastro associado ao sequencial. |

### Documento técnico: `configuracoes/log_clientes`

| Campo Firestore | Tipo | Regra |
| :--- | :--- | :--- |
| `sequencial_clientes` | number | Incrementa exatamente +1 por novo cliente. |
| `ultimo_horario_cadastro` | timestamp | Nunca pode ser menor que o ultimo valor salvo. |
| `atualizado_em` | timestamp | Carimbo técnico de atualização. |

---

## 3. Planejamento: Módulo Financeiro (Futuro)

Variáveis mapeadas para a implementação do controle financeiro e pagamentos.

### Nova Coleção: `transacoes_financeiras`
*   **Identificadores:**
    *   `transacao_id` (PK): Identificador único da transação.
    *   `agendamento_id` (FK): Vínculo com o serviço prestado (pode ser nulo se for venda de produto avulso).
    *   `cliente_uid` (FK): Quem pagou.
    
*   **Valores:**
    *   `valor_bruto`: Valor total do serviço/produto.
    *   `valor_desconto`: Desconto aplicado.
    *   `valor_liquido`: Valor final cobrado.
    
*   **Detalhes do Pagamento:**
    *   `metodo_pagamento`: Enum (`pix`, `dinheiro`, `cartao_credito`, `pacote`).
    *   `status_pagamento`: Enum (`pendente`, `pago`, `estornado`).
    *   `data_pagamento`: Data efetiva da entrada do dinheiro.
    
*   **Auditoria:**
    *   `data_criacao`: Quando o registro foi gerado.
    *   `criado_por_uid`: ID de quem registrou (Admin ou Sistema).

---

## 4. Estratégia de Integridade (NoSQL)

Como o Firestore não possui "Foreign Keys" rígidas, adotaremos a estratégia de **Snapshotting** para dados críticos.

**Cenário:** O cliente "João" paga R$ 100,00. Um mês depois, o registro do cliente é anonimizado ou excluído.

**Solução:**
No documento da transação, não salvamos apenas `cliente_uid: "123"`. Salvamos:

```json
{
  "transacao_id": "tx_999",
  "cliente_uid": "123",
  "cliente_snapshot": {
    "nome": "Maria Joaquina da Silva",
    "cpf": "111.222.333-44"
  },
  "valor": 100.00
}
```

Dessa forma, mesmo que o perfil em `usuarios/{email}/perfil/cliente` seja anonimizado, o relatório financeiro continuará mostrando que "Maria Joaquina da Silva" pagou R$ 100,00 naquela data.

---
*Documento para padronização do TCC - Agenda Massoterapia.*