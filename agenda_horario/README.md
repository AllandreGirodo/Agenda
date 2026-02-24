# Agenda de Massoterapia

Este repositório contém o código-fonte do aplicativo de agendamento e gestão
para uma clínica de massoterapia. O objetivo do projeto é criar um sistema
móvel e web em Flutter que permita:

- Clientes entrarem com login seguro e visualizarem/agendarem horários.
- Enviar solicitações de alteração que são recebidas por WhatsApp pela
  administradora.
- Administradora (sua esposa) gerenciar a agenda em formato de calendário,
  controlar pagamentos de pacotes de sessões e estoque de materiais (cremes).
- Aplicação multilíngue (PT-BR, EN-US, ES) com arquitetura preparada para mais
  idiomas.
- Banco de dados NoSQL usando Firebase Firestore e autenticação via Firebase
  Authentication.

## Estrutura inicial

O projeto foi criado com `flutter create` e já possui um arquivo de exemplo
`main.dart` que mostra um contador. A partir daqui você deve construir as
funcionalidades listadas acima.

Pasta `lib/`:

- `models/` – classes Dart que representam clientes, agendamentos, pacotes,
  produtos etc.
- `view/` e `widgets/` – telas e componentes reutilizáveis.
- `controller/` – lógica de conexão com Firebase e regras de negócio.
- `app_localizations.dart` – arquivo centralizado de traduções.

## Como começar

1. **Configure o Firebase**
   - Crie um projeto no [console do Firebase](https://console.firebase.google.com/).
   - Ative Authentication (Email/Senha) e Cloud Firestore.
   - Baixe o `google-services.json`/`GoogleService-Info.plist` e copie para os
     diretórios nativos (`android/app`, `ios/Runner`).
   - Adicione dependências no `pubspec.yaml`:
     ```yaml
     dependencies:
       flutter:
         sdk: flutter
       firebase_core: ^2.10.0
       firebase_auth: ^4.2.0
       cloud_firestore: ^4.5.0
       flutter_localizations:
         sdk: flutter
     ```

2. **Inicialize o Git**
   ```bash
   git init
   git add .
   git commit -m "inicial: projeto Flutter de agendamento"
   ```
   Empurre para o GitHub/GitLab e faça commits freqüentes à medida que avança.

3. **Execute o app padrão**
   - Abra um emulador ou conecte um dispositivo (`flutter devices`).
   - Rode `flutter run` para verificar que o projeto compila.

4. **Implemente o MVP** (versão mínima viável):
   - Crie telas de login/cadastro com Firebase Auth.
   - Modele as coleções Firestore conforme o caderno (clientes,
     agendamentos, pacotes, produtos, templates_agenda, configurações).
   - Adicione internacionalização usando o arquivo de traduções.
   - Desenvolva a interface de agenda com `table_calendar` ou similar.

## Cronograma sugerido

Já estamos em fim de fevereiro de 2026 e a entrega é em abril:

- **20‑28 fev**: setup Flutter/Firebase, modelagem de dados e primeiras classes.
- **1‑15 mar**: login, CRUD de clientes e agendamento simples.
- **16‑31 mar**: pacotes/pagamentos, integração WhatsApp, controle de estoque.
- **1‑15 abr**: refinamento UI, testes de usabilidade e documentação final.
- **resto de abr**: ajustes e preparação da apresentação.

Dedique 30‑40 h por semana para cumprir o plano.

## Documentação acadêmica

Um anteprojeto já está disponível no workspace (`anteprojeto_tcc.md`). Ele
contém:

- Introdução, justificativa e objetivos.
- Referencial teórico (Flutter, Firestore, métodos ágeis etc.).
- Metodologia e cronograma.
- Estrutura sugerida para o relatório final.

Use-o como base para todo o texto do TCC e atualize conforme o desenvolvimento
avança.

## Contribuições e próximas tarefas

- Comece criando as classes em `lib/models/`.
- Configure a autenticação e a primeira tela de login.
- Defina o fluxo de agendamento com aprovação e notificação via WhatsApp.
- Implemente dashboard administrativo e componentes de calendário.

Fotos do caderno, esquemas de banco e outros rascunhos podem ser adicionados
a `docs/` ou anexados ao repositório.

Boa sorte! Trabalhando sistematicamente você terá um MVP funcional em poucas
semanas e um relatório completo para submeter ao orientador.