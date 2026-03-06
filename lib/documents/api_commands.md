# Comandos de Terminal para API Firestore

Estes comandos utilizam a API REST do Firestore para interagir com o banco de dados diretamente pelo terminal.

**Pré-requisitos:**
1.  Substitua `[PROJECT_ID]` pelo ID do seu projeto Firebase.
2.  Para operações de escrita, você precisará de um Token de Acesso (OAuth 2.0).

---

## 1. Listar Agendamentos (GET)

```bash
curl -X GET \
  "https://firestore.googleapis.com/v1/projects/[PROJECT_ID]/databases/(default)/documents/agendamentos"
```

## 2. Criar uma Transação Financeira (POST)

Este comando simula a criação de uma transação financeira via API.

```bash
curl -X POST \
  "https://firestore.googleapis.com/v1/projects/[PROJECT_ID]/databases/(default)/documents/transacoes_financeiras" \
  -H "Content-Type: application/json" \
  -d '{
  "fields": {
    "cliente_uid": { "stringValue": "teste_cliente_1" },
    "valor_liquido": { "doubleValue": 120.00 },
    "metodo_pagamento": { "stringValue": "pix" },
    "status_pagamento": { "stringValue": "pago" },
    "data_pagamento": { "timestampValue": "2026-02-25T10:00:00Z" },
    "criado_por_uid": { "stringValue": "admin_user" }
  }
}'
```

## 3. Consultar Cliente Específico (GET)

```bash
curl -X GET \
  "https://firestore.googleapis.com/v1/projects/[PROJECT_ID]/databases/(default)/documents/clientes/teste_cliente_1"
```

## 4. Executar Query (POST :runQuery)

Buscar agendamentos com status "pendente".

```bash
curl -X POST \
  "https://firestore.googleapis.com/v1/projects/[PROJECT_ID]/databases/(default)/documents:runQuery" \
  -H "Content-Type: application/json" \
  -d '{
  "structuredQuery": {
    "from": [{ "collectionId": "agendamentos" }],
    "where": { "fieldFilter": { "field": { "fieldPath": "status" }, "op": "EQUAL", "value": { "stringValue": "pendente" } } }
  }
}'
```