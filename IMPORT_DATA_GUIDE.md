# Guia de Importação Melhorada de Dados - Dev Tools

## Visão Geral

Implementamos uma nova funcionalidade de importação de dados no Dev Tools que oferece:

✅ **Validacao de Cabecalho**: Verifica se os campos obrigatórios estão presentes
✅ **Preview de Dados**: Mostra os primeiros registros antes de importar
✅ **Melhor UX**: Dialog com abas e informations claras
✅ **Suporte a CSV**: Importacao de planilhas em formato CSV

---

## Como Usar

### 1. Acessar a Importacao

No Dev Tools, localize o setor de "Clientes" e clique em **"Importar"** (ícone de planilha/tabela).

### 2. Selecionar Arquivo

- Selecione um arquivo `.csv` com seus dados de clientes
- O sistema suporta apenas CSV por enquanto (XLSX em desenvolvimento)

### 3. Validar Cabecalho

O sistema valida automaticamente se:
- ✅ Existe um campo "Telefone Principal" (ou similar)
- ✅ Existe um campo "Nome Principal" (ou similar)

**Se faltar algum**, você recebera mensagem de erro indicando qual campo esta faltando.

### 4. Revisar Preview

Uma dialog aparecera com:

- **Secao 1: Campos encontrados**
  - Lista de todos os campos detectados
  - Formatados como chips coloridos para fácil leitura

- **Secao 2: Preview de dados**
  - Primeiros 3 registros
  - Mostra os valores de cada campo
  - +X registros se houver mais

### 5. Confirmar Importacao

Clique em **"Importar"** para proceed ou **"Cancelar"** para desistir.

---

## Formato Esperado do Arquivo CSV

### Campos Obrigatorios

| Campo | Tipo | Exemplo | Formato |
|-------|------|---------|---------|
| Telefone Principal | String | 11999887766 | Apenas números (0-9) |
| Nome Principal | String | João Silva | Qualquer texto |

### Campos Opcionais

| Campo | Tipo | Exemplo | Descricao |
|-------|------|---------|-----------|
| Nome Preferido | String | João | Como ele gosta de ser chamado |
| DDI | String | 55 | Prefixo internacional |
| CPF | String | 12345678901 | Com ou sem formatacao |
| Data Nascimento | Date | 15/01/1990 | Formato DD/MM/YYYY |
| Endereco | String | Rua A, 123 | Endereco completo |
| CEP | String | 01234567 | Com ou sem hífen |
| Nome Contato Secundario | String | Maria | Nome do contato alternativo |
| Telefone Secundário | String | 1133334444 | Apenas números |
| Nome Indicacao | String | Maria | Quem indicou |
| Telefone Indicacao | String | 11988776655 | Contato de quem indicou |
| Categoria Origem | String | indicacao | Como conheceu (web, whatsapp, etc) |
| Historico Medico | String | ... | Informacoes médicas relevantes |
| Alergias | String | Dipirona | Alergias conhecidas |
| Medicamentos | String | ... | Medicamentos em uso |
| Cirurgias | String | ... | Cirurgias recentes |
| Anamnese Ok | Boolean | true | Se anamnese está validada |
| Presenca Agenda | Boolean | false | Sinal histórico de presença |
| Frequencia Historica Agenda | Int | 3 | Frequência de recorrência |
| Ultimo Horario Agendado | String | 18:00 | Último horário conhecido |
| Ultimo Dia Semana Agendado | String | quarta_feira | Último dia recorrente |
| Sugestao Cliente Fixo | Boolean | true | Heurística para cliente fixo |
| Saldo Sessoes | Int | 10 | Créditos de sessões |
| Favoritos | String | relaxante;terapeutica | Lista separada por `;` ou `,` |
| Horarios Recorrentes | String | seg 18h \| qua 18h | Resumo livre de recorrência |
| Outro Horario 1..5 | String | sexta 18h | Preferências adicionais |
| Domingo/Segunda/.../Sabado Fixo | Boolean | true/false | Agenda fixa semanal |

---

## Exemplo de Arquivo CSV

```csv
Telefone Principal,Nome Principal,Nome Preferido,DDI,Data Nascimento,Anamnese Ok,Saldo Sessoes,Horarios Recorrentes,Outro Horario 1,Outro Horario 2,Domingo Fixo,Segunda Feira Fixo,Terca Feira Fixo,Quarta Feira Fixo,Quinta Feira Fixo,Sexta Feira Fixo,Sabado Fixo
11999887766,João Silva,João,55,15/01/1990,true,10,seg 18h | qua 18h,domingo 09h,quarta 18h,false,true,false,true,false,false,false
11988776655,Maria Santos,Mari,55,22/05/1985,true,0,ter 09h,terca 09h,quinta 09h,false,false,true,false,true,false,false
11977665544,Pedro Oliveira,Pedro,55,01 /01/1990,false,4,sex 18h30,sexta 18h30,domingo 09h,true,true,false,false,false,true,false
```

---

## O que Acontece Na Importacao

1. **Leitura**: O arquivo is lido e parseado
2. **Validacao**: Cada registro é validado
3. **Normalizacao**: Dados são formatados corretamente (telefone, data, etc)
4. **Persistencia**: Dados sao salvos no Firestore
5. **Relatorio**: Mostra quantos registros foram
   - Importados: ✅
   - Ignorados: ⚠️ (sem telefone válido)
   - Com Erro: ❌ (erro de processamento)

---

## Normalizacao Autormatica

O sistema automaticamente:

- ✅ Remove formatacao de telefones (guarda apenas números)
- ✅ Remove DDI 55 se telefone > 11 dígitos
- ✅ Normaliza nomes de campos (maiuscula, acentos, espacos)
- ✅ Limpa dados vazios

---

## Regras de Importacao

### Telefone

- **Obrigatorio**: Cada cliente precisa de um telefone valido
- **Valido**: Minimo 8 dígitos após normalizacao
- **Multiplos nomes**: Aceita "Telefone Principal", "WhatsApp", "Telefone", etc

### Nome

- **Obrigatorio**: Cada cliente precisa de nome
- **Multiplos nomes**: Aceita "Nome Principal", "Nome", "Cliente", etc

### Ignorados

Registros **SEM TELEFONE VALIDO** sao automaticamente ignorados:
- Telefone vazio
- Telefone com menos de 8 dígitos
- Telefone sem dígitos válidos

---

## Troubleshooting

### ❌ "Campo obrigatorio nao encontrado"

**Problema**: Arquivo faltando "Telefone Principal" ou "Nome Principal"

**Solucao**: 
- Verifique se seu arquivo tem colunas com esses nomes
- Nomes similares sao aceitos (ex: "WhatsApp", "Tel?­fone")

### ❌ "Formato CSV nao suportado"

**Problema**: Tentou importar arquivo XLSX/XLS

**Solucao**: 
- Converta para CSV primeiro (File > Save As > Comma Separated Values)
- Suporte a XLSX será adicionado em breve

### ⚠️ "Muitos registros ignorados"

**Problema**: Maioria dos registros foram ignorados

**Solucao**: 
- Verifique se a coluna de telefone tem dados válidos
- Minimo 8 dígitos após limpeza
- Sem letras ou caracteres especiais

---

## Implementacao Tecnica

### Arquivos Envolvidos

1. **lib/view/dev_tools_view.dart**
   - Metodo: `importarPlanilhaClientes()`
   - Maneja UI e coordenacao

2. **lib/view/import_preview_dialog.dart**
   - Metodo: `ImportPreviewHelper`
   - Helper para validacao e preview

3. **lib/core/utils/app_strings.dart**
   - Strings de texto da interface

4. **lib/core/services/firestore_service.dart**
   - Metodo: `importarPlanilhaClientes()`
   - Persistencia no Firestore

### Fluxo

```
selecionar arquivo CSV
    ↓
fazer parsing (headers + dados)
    ↓
validar cabecalho (obrigatorios)
    ↓
mostrar preview dialog
    ↓
[ usuario clica em "Importar" ]
    ↓
processar cada registro
    ↓
persistir no Firestore
    ↓
mostrar resultado
```

---

## Proximas Melhorias (Roadmap)

- [ ] Suporte a XLSX/XLS
- [ ] Preview de validacoes por campo
- [ ] Mapeamento customizado de colunas
- [ ] Importacao de agendamentos
- [ ] Importacao em lote (dropzone)
- [ ] Download de template CSV

---

## Duvidas?

Para mais informacoes sobre o desenvolvimento, veja:
- `IMPLEMENTATION_GUIDE.md` - Guia de implementacao geral
- `dicionario_dados_variaveis.md` - Dicionário de campos
- `lib/core/models/cliente_model.dart` - Modelo de Cliente
