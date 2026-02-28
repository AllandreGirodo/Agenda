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

### Coleção: `clientes`
| Variável Dart | Campo Firestore Atual | Sugestão de Melhoria | Motivo |
| :--- | :--- | :--- | :--- |
| `uid` | `uid` | `cliente_uid` | Padronização. |
| `saldoSessoes`| `saldo_sessoes` | `saldo_pacote_atual` | Clareza que se refere a pacotes. |
| `anamneseOk` | `anamnese_ok` | `is_anamnese_preenchida` | Booleano explícito. |

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
    "nome": "João da Silva",
    "cpf": "111.222.333-44"
  },
  "valor": 100.00
}
```

Dessa forma, mesmo que o documento original em `clientes/123` vire "Anonimizado", o relatório financeiro continuará mostrando que "João da Silva" pagou R$ 100,00 naquela data.

---
*Documento gerado para padronização do TCC - Agenda Massoterapia.*