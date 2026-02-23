# Agenda

Anteprojeto de Trabalho de Conclusão de Curso

Título: Sistema de Agendamento e Gestão para Profissionais de Massoterapia utilizando Flutter e Dart

Discente: Allandre Ramos Girodo
Orientador: Prof. Júnior César Bonafim

Instituição: Faculdade de Tecnologia de Ribeirão Preto (FATEC)
Ribeirão Preto, SP – Brasil
E-mail: 

$$allandre.girodo@fatec.sp.gov.br$$

1. Introdução

O mercado de serviços de bem-estar e estética corporal tem apresentado um crescimento consistente, exigindo que profissionais autônomos adotem processos mais eficientes de gestão. No cenário atual, a massoterapia itinerante e fixa enfrenta desafios logísticos complexos, como a gestão de janelas de atendimento, controle de estoque de insumos (cremes) e fidelização através de pacotes de sessões. Este trabalho propõe o desenvolvimento de uma aplicação multiplataforma para automatizar essas tarefas, substituindo registros manuais por uma solução digital robusta.

2. Problema e Justificativa

A gestão manual, baseada em agendas físicas ou planilhas simples, impossibilita a análise em tempo real da disponibilidade de profissionais e o controle preciso do consumo de materiais. A falha na coordenação de horários gera "gargalos" operacionais, enquanto a falta de um sistema de baixa automática de estoque pode interromper a prestação de serviços por falta de insumos. Este projeto justifica-se pela necessidade de profissionalizar a gestão de microempreendedores, utilizando tecnologias de ponta como Flutter e Firebase para oferecer uma ferramenta de baixo custo e alta eficiência.

3. Objetivos

3.1. Objetivo Geral

Desenvolver uma aplicação mobile e web utilizando o framework Flutter para a gestão de agendamentos, clientes e estoque em clínicas de massoterapia.

3.2. Objetivos Específicos

Módulo de Agendamento: Implementar lógica de aprovação da administradora para solicitações de horários.

Módulo de Pacotes: Controlar a venda e validade de pacotes de sessões (conforme regras de 61 dias e fidelização).

Módulo de Estoque: Desenvolver algoritmo de baixa automática de cremes baseado no tipo de serviço prestado.

Persistência: Utilizar Google Firebase Firestore para armazenamento NoSQL em tempo real.

4. Metodologia

A metodologia adotada é a Pesquisa-Ação, onde o desenvolvedor atua diretamente no ambiente do problema (a clínica da esposa) para coletar requisitos. O desenvolvimento seguirá o modelo Ágil, com entregas semanais (Sprints) focadas no MVP (Mínimo Produto Viável) até abril de 2026.

5. Cronograma de Sprints (Fev - Abr 2026)

Período

Sprint

Foco

Fev (20-28)

Sprint 1

Setup do Ambiente, Git, Firebase e Modelagem de Dados.

Mar (01-15)

Sprint 2

Auth (Login) e Fluxo de Agendamento (Agenda Itinerante).

Mar (16-31)

Sprint 3

Gestão de Pacotes, Pagamentos e Baixa de Estoque.

Abr (01-15)

Sprint 4

Testes de Usabilidade, Refinamento de UI e Documentação Final.

6. Referências Bibliográficas (Principais)

PRESSMAN, R. S. Engenharia de Software: uma abordagem profissional. 9. ed. 2021.

SADALAGE, P. J.; FOWLER, M. NoSQL Essencial. Novatec, 2013.

GOOGLE. Flutter Documentation. 2026.