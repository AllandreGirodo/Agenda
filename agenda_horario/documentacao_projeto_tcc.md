# Documentação do Projeto de TCC - Agenda Massoterapia

**Aluno:** [Seu Nome]
**Tema:** Sistema de Agendamento e Gestão para Clínica de Massoterapia
**Tecnologias:** Flutter, Firebase (Auth, Firestore, Storage), Dart.

---

## 1. Levantamento de Requisitos

O sistema foi projetado para resolver o problema de gestão manual (caderno/WhatsApp) de uma massoterapeuta autônoma.

### 1.1. Requisitos Funcionais (RF)

*   **[RF001] Autenticação e Cadastro:**
    *   O sistema deve permitir login por e-mail e senha.
    *   Novos usuários (clientes) entram como "pendentes" até aprovação ou validação automática.
    *   O sistema deve diferenciar perfis de usuário: `Administrador` e `Cliente`.

*   **[RF002] Gestão de Perfil e Anamnese (LGPD):**
    *   O cliente deve preencher dados pessoais (Nome, CPF, Endereço).
    *   O cliente deve preencher ficha de anamnese (Histórico médico, alergias, cirurgias).
    *   O cliente deve ter a opção de excluir seus dados permanentemente (Direito ao Esquecimento - LGPD).
    *   **Validações:** O sistema deve validar CPF e buscar endereço automaticamente via CEP.

*   **[RF003] Agendamento de Sessões:**
    *   O cliente visualiza horários disponíveis e solicita agendamento.
    *   O status inicial é "Pendente".
    *   A administradora aprova ou recusa o agendamento.
    *   Cancelamentos devem exigir justificativa e respeitar antecedência configurada.

*   **[RF004] Integração com WhatsApp:**
    *   O sistema deve permitir abrir o WhatsApp da administradora para contato rápido.
    *   O sistema deve verificar se o app do WhatsApp está instalado ou usar a versão web.

*   **[RF005] Gestão Administrativa:**
    *   Dashboard com métricas (agendamentos do dia, receita estimada).
    *   Controle de Estoque (baixa automática de produtos ao aprovar sessão).
    *   Configurações globais (preço da sessão, telefone da admin, horário de sono para regras de cancelamento).

### 1.2. Requisitos Não-Funcionais (RNF)

*   **[RNF001] Disponibilidade:** O sistema deve operar em dispositivos móveis (Android/iOS).
*   **[RNF002] Usabilidade:** Interface intuitiva para usuários leigos.
*   **[RNF003] Segurança:** Regras de segurança no banco de dados (Firestore Rules) para impedir acesso não autorizado a dados médicos.

---

## 2. Histórico de Desenvolvimento e Decisões Técnicas

Esta seção registra os desafios encontrados durante a codificação e as soluções aplicadas, servindo de base para a defesa técnica do TCC.

### 2.1. Configuração de Dependências e Erros de Compilação
*   **Problema:** Erro `Target of URI doesn't exist: 'package:url_launcher/url_launcher.dart'`.
*   **Causa:** A biblioteca `url_launcher` não estava listada no `pubspec.yaml`.
*   **Solução:** Adição da dependência `url_launcher: ^6.3.0` e execução do `flutter pub get`.

### 2.2. Integração com Aplicativos Nativos (WhatsApp)
*   **Problema:** O aplicativo não abria o WhatsApp, ou falhava silenciosamente em versões novas do Android/iOS.
*   **Decisão Técnica:**
    1.  **Android:** Adição da tag `<queries>` no `AndroidManifest.xml` para permitir visibilidade dos esquemas `https`, `http`, `tel`, `mailto` e o pacote `com.whatsapp`. Isso é exigência do Android 11 (API 30+).
    2.  **iOS:** Adição da chave `LSApplicationQueriesSchemes` no `Info.plist` para permitir verificar `canLaunchUrl`.
    3.  **Lógica (Dart):** Implementação de fallback. Tenta abrir `whatsapp://` (app nativo); se falhar, abre `https://wa.me` (navegador).

### 2.3. Dinamismo nas Configurações
*   **Questão:** O número de telefone da administradora estava "hardcoded" (fixo) no código.
*   **Solução:** Criação da coleção `configuracoes` no Firestore. O app agora busca o telefone em tempo real (`FirestoreService().getTelefoneAdmin()`), permitindo que a administradora troque de número sem precisar atualizar o app nas lojas.

### 2.4. Qualidade de Dados (Validação de CPF e CEP)
*   **Desafio:** Garantir que os dados cadastrais sejam válidos.
*   **Solução Implementada:**
    *   **CPF:** Implementação do algoritmo de validação de dígitos verificadores (Módulo 11) e máscara de entrada (`xxx.xxx.xxx-xx`) usando `TextInputFormatter`.
    *   **Endereço:** Integração com API pública `ViaCEP`. Ao digitar 8 dígitos no campo CEP, o sistema faz uma requisição HTTP e preenche Logradouro, Bairro e Cidade automaticamente.

### 2.5. Upload de Imagens e Armazenamento
*   **Desafio:** Permitir que o usuário tenha foto de perfil.
*   **Limitação:** Não é possível obter a foto do WhatsApp via API pública por privacidade.
*   **Solução:** Uso do `image_picker` para selecionar foto da galeria e `firebase_storage` para salvar na nuvem.
*   **Segurança:** Configuração das *Storage Rules* para permitir que o usuário faça upload apenas na sua própria pasta (`perfis/{uid}.jpg`), mas permitindo leitura pública (para a Admin ver a foto).

---

## 3. Trabalhos Futuros (Roadmap)

Funcionalidades mapeadas que não entraram no MVP (Mínimo Produto Viável) mas são sugeridas para continuidade do projeto:

1.  **Pagamento Online:**
    *   Integração com Gateway de Pagamento (Mercado Pago ou Stripe) para exigir pagamento ou sinal no momento do agendamento.

2.  **Notificações Push Reais:**
    *   Atualmente o sistema prepara o token FCM, mas o envio depende de um Backend (Cloud Functions). Implementar "Triggers" no Firestore para enviar notificação quando o status do agendamento mudar.

3.  **Sincronização com Google Calendar:**
    *   Permitir que a administradora veja os agendamentos do app diretamente na sua agenda pessoal do Google.

4.  **Relatórios Avançados:**
    *   Gráficos de evolução financeira anual e sazonalidade de clientes.

---

## 4. Estrutura de Banco de Dados (Firestore)

Documentação das coleções utilizadas:

*   **`usuarios`**: Dados de login, tipo de acesso (admin/cliente) e token de notificação.
*   **`clientes`**: Dados pessoais, anamnese, saldo de sessões e endereço.
*   **`agendamentos`**: Data, hora, status (pendente/aprovado/cancelado), motivo e lista de espera.
*   **`estoque`**: Produtos, quantidade e flag de consumo automático.
*   **`configuracoes`**: Variáveis globais do sistema.
*   **`logs`**: Auditoria de ações críticas (quem cancelou, quem aprovou).

---

## 5. Perguntas Frequentes durante o Desenvolvimento (FAQ TCC)

**P: Por que usar Flutter e não nativo (Kotlin/Swift)?**
*R: Para permitir o desenvolvimento de uma única base de código que atenda tanto Android quanto iOS, reduzindo tempo de desenvolvimento e manutenção, ideal para um projeto de TCC individual.*

**P: Por que NoSQL (Firestore) e não SQL?**
*R: Pela flexibilidade do esquema (schema-less), facilidade de integração com o Flutter (reatividade em tempo real com Streams) e custo inicial zero no plano Spark.*

**P: Como o sistema lida com cancelamentos tardios?**
*R: O sistema calcula a diferença entre a hora atual e a hora do agendamento, descontando o "horário de sono" configurado pela admin. Se o tempo útil for menor que o limite, o cancelamento é marcado como "tardio" e exige justificativa.*

---