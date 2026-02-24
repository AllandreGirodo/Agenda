# Estrutura do Relatório Final de TCC (Baseada no Modelo Aprovado)

Allandre, ajustei esta estrutura para espelhar o nível de detalhe do TCC do Caio Sousa, adaptando para Software e Gestão.

## 1. Elementos Pré-Textuais

*   **Capa e Folha de Rosto:** Conforme padrão FATEC Ribeirão Preto.
*   **Resumo / Abstract:** (Escrever por último) Deve conter o objetivo, a tecnologia (Flutter/Firebase) e o principal resultado (ex: redução de 20% no tempo de agendamento manual).

## 2. Capítulos do Trabalho

### Capítulo 1: Introdução

*   **1.1 Introdução:** Contexto da massoterapia e serviços autônomos.
*   **1.2 Problema:** A dificuldade de gerir agenda, stock de cremes e pacotes de forma manual (as "dores" da sua esposa).
*   **1.3 Objetivos:** Geral (desenvolver o app) e Específicos (Autenticação, CRUD, Gestão de Stock).
*   **1.4 Justificativa:** Impacto económico e profissionalização do pequeno negócio.

### Capítulo 2: Referencial Teórico (Fundamentação)

Seguindo o estilo do PDF, aqui você cita os "gigantes":

*   **2.1 Desenvolvimento Cross-Platform:** Estudo sobre o ecossistema Flutter/Dart.
*   **2.2 Persistência de Dados NoSQL:** Fundamentação do Firestore (citações de Fowler/Sadalage).
*   **2.3 Engenharia de Requisitos:** O processo de transcrever o "caderno" para o sistema.
*   **2.4 Logística em Serviços de Estética:** (Novo) Conceitos de agendamento itinerante.

### Capítulo 3: Levantamento e Análise de Requisitos

Aqui entra o que estava no seu caderno:

*   **3.1 Descrição do Negócio:** Fluxo de trabalho da massoterapeuta.
*   **3.2 Requisitos Funcionais:** (O que o app faz: agendar, cancelar, gerir stock).
*   **3.3 Requisitos Não Funcionais:** (Segurança, performance, disponibilidade).
*   **3.4 Modelagem de Dados:** Explicar a estrutura JSON das coleções.

### Capítulo 4: Desenvolvimento do Sistema (A sua "Modelagem")

No TCC do Caio, este foi o capítulo 4 e 5. Para você:

*   **4.1 Arquitetura da Aplicação:** Como organizou as pastas no VS Code.
*   **4.2 Integração Firebase:** Como configurou o Auth e o Firestore.
*   **4.3 Lógica de Negócio:** Explicar a regra de "Validação da Administradora" e "Cálculo de Consumo de Creme".

### Capítulo 5: Resultados e Discussão

*   **5.1 Testes de Usabilidade:** Relato da experiência da sua esposa ao usar o sistema.
*   **5.2 Avaliação Técnica:** O sistema atendeu aos requisitos?
*   **5.3 Comparação:** Antes (Manual/Caderno) vs. Depois (App).

### Capítulo 6: Considerações Finais

Limitações encontradas e sugestões para pesquisas futuras (ex: integração com pagamentos automáticos).

## 3. Fontes Bibliográficas (Expandidas)

*   SOMMERVILLE, Ian. Engenharia de Software. 10. ed. São Paulo: Pearson, 2018.
*   FLUTTER. Flutter Documentation. Disponível em: https://docs.flutter.dev.
*   GOOGLE. Firebase Documentation. Disponível em: https://firebase.google.com/docs.
*   FOWLER, Martin. Padrões de Arquitetura de Aplicações Corporativas. Porto Alegre: Bookman, 2006.
*   SEBRAE. O mercado de massoterapia no Brasil. (Pesquisa recente para a Introdução).