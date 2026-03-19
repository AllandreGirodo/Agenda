# Anteprojeto de Trabalho de Conclusão de Curso (TCC)

**Título provisório:** Sistema de Agendamento e Gestão para Profissionais de Massoterapia utilizando Flutter e Dart  
**Discente:** Allandre Ramos Girodo  
**Orientador:** Prof. Júnior César Bonafim  
**Instituição:** Faculdade de Tecnologia de Ribeirão Preto (FATEC)  
**Data:** Março de 2026  

> **Status do documento:** versão expandida para validação de escopo. Campos marcados com **[PREENCHER]** dependem de métricas/detalhes que ainda não foram informados.

---

## 1. Resumo

Este trabalho propõe o desenvolvimento de uma aplicação multiplataforma (Mobile e Web) para apoiar a gestão de atendimentos de massoterapia, com foco em: (i) agendamento de sessões (fixas e itinerantes), (ii) cadastro de clientes, (iii) controle de pacotes de sessões, e (iv) apoio ao controle de materiais/insumos e registros financeiros básicos. A solução será implementada com Flutter/Dart e Firebase, priorizando um MVP com funcionalidades essenciais e validação com usuários reais.

**Palavras-chave:** agendamento; massoterapia; Flutter; Firebase; gestão de serviços.

---

## 2. Contextualização, Introdução e Problema

Profissionais autônomos e pequenas clínicas de estética corporal frequentemente realizam o controle de agenda, pacotes e insumos por meios informais (papel, planilhas e aplicativos genéricos). Esse cenário pode gerar conflitos de horários, cancelamentos mal gerenciados, perda de rastreabilidade de pacotes de sessões e dificuldade de controle de materiais utilizados por atendimento.

**Problema de pesquisa (formulação):**
- Como estruturar e validar um MVP de agendamento e gestão para massoterapeutas que reduza conflitos de agenda e melhore o controle de pacotes e insumos, mantendo simplicidade de uso e baixo custo?

**Hipótese/pressuposto (opcional):**
- A adoção de um fluxo de agendamento com estados (solicitado/aprovado/realizado/cancelado) e registro por sessão tende a reduzir conflitos e aumentar a rastreabilidade dos atendimentos.

---

## 3. Justificativa

A digitalização de processos de agenda e gestão operacional pode aumentar a eficiência e reduzir perdas em pequenos negócios de serviços. Além disso, o uso de soluções multiplataforma (Flutter) e backend gerenciado (Firebase) pode reduzir o custo de manutenção e acelerar a entrega de um MVP.

> Observação: o texto original menciona Pesquisa Operacional e analogia ao TTP. Para manter o anteprojeto aderente e executável no prazo, a aplicação de Pesquisa Operacional deve ser delimitada (ex.: heurística simples de sugestão de horários/roteiro) ou reposicionada como **trabalho futuro**.

---

## 4. Objetivos

### 4.1 Objetivo Geral

Desenvolver e validar um **MVP funcional** de um sistema de agendamento e gestão de atendimentos de massoterapia até **[PREENCHER: data final exata — ex.: 2026-04-30]**.

### 4.2 Objetivos Específicos

1. Implementar autenticação e perfis de acesso (ex.: profissional/admin).  
2. Implementar cadastro e consulta de clientes.  
3. Implementar módulo de agendamento com estados e regras de conflito.  
4. Implementar controle de pacotes de sessões por cliente (saldo, consumo, validade se aplicável).  
5. Implementar registro de sessão realizada com baixa automática de insumos (escopo mínimo) e/ou estoque (escopo estendido).  
6. Implementar relatórios básicos (ex.: sessões por período; receita estimada; consumo de insumos).  
7. Realizar testes com usuários reais e registrar resultados.

---

## 5. Escopo e Delimitações

### 5.1 Escopo do MVP (entregas obrigatórias)

- **Agenda:** criar/editar/cancelar sessões.
- **Fluxo de status:** solicitado → aprovado → realizado (ou cancelado).
- **Conflitos de agenda:** impedir dois atendimentos no mesmo horário para o mesmo profissional.
- **Clientes:** cadastro e histórico de sessões.
- **Pacotes:** compra/registro de pacote; consumo por sessão.
- **Relatórios simples:** listagem e filtros por data.

### 5.2 Fora do escopo (neste TCC)

- Integração com meios de pagamento (PIX/cartão).
- Emissão fiscal/nota.
- Marketplace/assinatura.
- Otimização avançada (Pesquisa Operacional completa) — **a menos que seja definido um recorte implementável**.

### 5.3 Premissas

- Uso do Firebase (Auth + Firestore) como backend.
- Disponibilidade de ao menos **[PREENCHER: N]** usuários para teste.

---

## 6. Requisitos

### 6.1 Requisitos Funcionais (RF)

- **RF01** — Autenticar usuário (login/logout/recuperação).
- **RF02** — Cadastrar/editar/excluir clientes.
- **RF03** — Criar/editar/cancelar agendamentos.
- **RF04** — Aprovar/rejeitar agendamentos (quando aplicável).
- **RF05** — Registrar sessão realizada.
- **RF06** — Controlar pacotes (saldo de sessões) e dar baixa automaticamente ao registrar sessão.
- **RF07** — Registrar uso de insumos por sessão (mínimo) e/ou atualizar estoque (estendido).
- **RF08** — Gerar relatórios básicos (período; cliente; status).

### 6.2 Requisitos Não Funcionais (RNF)

- **RNF01 (Segurança)** — Restringir acesso a dados por regras do Firestore (ex.: cada profissional vê seus dados).
- **RNF02 (Usabilidade)** — Fluxos principais devem ser concluídos em **[PREENCHER: tempo alvo, ex.: ≤ 60s]** para criar um agendamento em cenário comum.
- **RNF03 (Performance)** — Listagens devem carregar em **[PREENCHER: meta, ex.: ≤ 2s]** em condições normais.
- **RNF04 (Confiabilidade)** — Persistência dos dados e histórico de alterações essenciais (ao menos log de status do agendamento).
- **RNF05 (LGPD)** — Minimização de dados pessoais, consentimento e possibilidade de exclusão/anonimização **[PREENCHER: como será tratado]**.

---

## 7. Metodologia

- **Tipo de pesquisa:** aplicada, com levantamento bibliográfico e estudo de caso/validação em campo.
- **Processo de desenvolvimento:** iterativo e incremental (sprints).
- **Técnicas:** elicitação de requisitos com entrevistas rápidas; prototipação; implementação; testes com usuários.

### 7.1 Plano de validação (testes com usuário)

- Perfil dos participantes: **[PREENCHER: ex.: massoterapeutas autônomos e/ou recepcionistas de clínica]**.
- Quantidade de participantes: **[PREENCHER: N]**.
- Tarefas do teste (mínimo):
  1. Cadastrar um cliente
  2. Criar um agendamento
  3. Aprovar e marcar como realizado
  4. Conferir saldo de pacote
  5. Visualizar relatório do período

### 7.2 Métricas de avaliação (a definir)

- **M1 — Taxa de sucesso por tarefa (%):** **[PREENCHER: meta, ex.: ≥ 80%]**
- **M2 — Tempo médio para criar agendamento:** **[PREENCHER: meta]**
- **M3 — Número médio de erros por tarefa:** **[PREENCHER: meta]**
- **M4 — Satisfação (SUS ou nota 0–10):** **[PREENCHER: métrica escolhida e meta]**

---

## 8. Solução proposta (visão técnica)

### 8.1 Tecnologias

- Flutter + Dart
- Firebase Authentication
- Cloud Firestore
- (Opcional) Cloud Functions

### 8.2 Arquitetura (proposta)

- Camadas sugeridas: apresentação (UI) → aplicação (casos de uso) → dados (repositórios) → Firebase.
- Gerenciamento de estado: **[PREENCHER: Provider/Riverpod/BLoC/etc.]**.

### 8.3 Modelo de dados (rascunho)

Coleções sugeridas:
- `users` (perfil, permissões)
- `clients` (dados mínimos)
- `appointments` (data/hora, local, status, cliente, notas)
- `packages` (cliente, saldo, validade)
- `sessions` (vínculo com appointment, insumos usados)
- `inventory` (itens e quantidades) **[se entrar no MVP]**

---

## 9. Cronograma

> Substituir “semana 01-02” por datas reais.

| Período | Atividade | Entregável |
| :--- | :--- | :--- |
| **[PREENCHER: 2026-??-?? a 2026-??-??]** | Setup do ambiente, modelagem Firestore e autenticação | Login + regras iniciais + modelo base |
| **[PREENCHER: 2026-??-?? a 2026-??-??]** | Módulo de clientes + agenda | CRUD clientes + calendário |
| **[PREENCHER: 2026-??-?? a 2026-??-??]** | Pacotes + sessão realizada + relatórios | Baixa de pacote + relatório básico |
| **[PREENCHER: 2026-??-?? a 2026-??-??]** | Testes com usuário, correções e redação final | Relatório final + resultados |

---

## 10. Riscos e Mitigações

- **R1 — Escopo amplo demais.** Mitigação: congelar escopo do MVP e mover extras para “trabalhos futuros”.
- **R2 — Falta de usuários para teste.** Mitigação: garantir participantes até **[PREENCHER: data]**.
- **R3 — Complexidade de regras do Firestore/LGPD.** Mitigação: regras mínimas + revisão orientada a perfis.

---

## 11. Referências Bibliográficas (inicial)

- PRESSMAN, R. S. *Engenharia de Software*. McGraw-Hill, 2016.
- SADALAGE, P. J.; FOWLER, M. *NoSQL Essencial*. Novatec, 2013.
- FLUTTER. Documentação oficial. Disponível em: https://docs.flutter.dev.
- (Sugestão para complementar) Nielsen/Norman (usabilidade), e/ou literatura de engenharia de requisitos.