# Diretrizes de Privacidade e Adequação à LGPD

Este documento descreve como o sistema **Agenda Massoterapia** trata os dados dos usuários, em conformidade com a **Lei Geral de Proteção de Dados (Lei nº 13.709/2018)**, especificamente sobre o direito de exclusão e a retenção de dados para cumprimento de obrigação legal.

## 1. Coleta de Metadados de Autenticação
Para segurança e auditoria, o sistema armazena automaticamente as seguintes informações fornecidas pelo provedor de identidade (Firebase Auth):
*   **UID:** Identificador único do usuário.
*   **Data de Criação da Conta:** Para saber quando o usuário iniciou o relacionamento.
*   **Último Login:** Para identificar contas inativas.

## 2. Direito de Exclusão vs. Retenção Legal (Art. 16)

Quando um usuário solicita a **"Exclusão da Conta"**, o sistema realiza um processo de **ANONIMIZAÇÃO**, e não a exclusão física total de todos os registros.

### O que é apagado (Dados Pessoais Sensíveis):
Para proteger a privacidade do titular, os seguintes dados são removidos ou ofuscados permanentemente:
*   Nome Completo (Substituído por "Usuário Anonimizado").
*   Telefone / WhatsApp.
*   Endereço Residencial.
*   Foto de Perfil.
*   Ficha de Anamnese (Histórico Médico, Alergias, Cirurgias).
*   E-mail (Removido da base de busca, mantido apenas hash ou ID interno se necessário).

### O que é mantido (Histórico Financeiro e Operacional):
Conforme o **Artigo 16, inciso I da LGPD**, os dados podem ser conservados para **cumprimento de obrigação legal ou regulatória pelo controlador**.

Portanto, mantemos:
*   **Registros de Agendamentos Realizados:** Datas e horários de serviços prestados.
*   **Histórico de Pagamentos/Pacotes:** Para contabilidade e auditoria fiscal da clínica.
*   **Logs de Auditoria:** Registro de que a solicitação de exclusão foi feita e atendida.

Desta forma, garantimos que o histórico financeiro da empresa (faturamento) não seja alterado pela saída de um cliente, ao mesmo tempo que impedimos a identificação direta da pessoa após o término do vínculo.

## 3. Coleção `lgpd_logs`
Todas as solicitações de exclusão e alterações sensíveis são registradas em uma coleção separada chamada `lgpd_logs`, contendo:
*   Data e Hora da solicitação.
*   Tipo de ação (Ex: "Anonimização de Conta").
*   ID do usuário afetado.

---
*Documento técnico para fins de desenvolvimento e auditoria do sistema.*