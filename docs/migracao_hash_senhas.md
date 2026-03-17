# Migracao de Hash de Senha

Este guia cobre duas frentes:

1. Auditar hashes existentes no Firestore
2. Migrar para formato seguro de senha (bcrypt/Argon2)

## Contexto deste projeto

- O campo senha_hash atual aparece em logs de auditoria de credenciais.
- O app usa Firebase Auth para autenticacao principal.
- Logo, qualquer mudanca de hash deve preservar o fluxo de auditoria e nao quebrar login Firebase.

## Objetivo recomendado

- Para credenciais de autenticacao customizada: usar Argon2id ou bcrypt.
- Para auditoria (sem necessidade de validacao posterior):
  - evitar armazenar derivacao de senha real quando possivel,
  - preferir metadados de inconformidade,
  - ou usar HMAC server-side com chave em secret manager.

## Passo 1 - Classificar o que existe hoje

Use o script:

- scripts/auditoria_senha_hash_firestore.js

Execucao tipica:

1. npm init -y
2. npm install firebase-admin
3. Defina GOOGLE_APPLICATION_CREDENTIALS apontando para service account JSON
4. node scripts/auditoria_senha_hash_firestore.js

Saida:

- hash_audit_report.json
- distribuicao por formato (sha1, sha256, bcrypt, argon2, etc)

## Passo 2 - Definir politica de destino

Escolha uma politica unica:

- Opcao A (recomendada para auth custom): Argon2id
- Opcao B (boa compatibilidade): bcrypt custo 12
- Opcao C (auditoria apenas): nao persistir hash de senha do usuario; usar apenas sinalizadores de risco

## Passo 3 - Migracao sem downtime

Estrategia por versao:

1. Introduza campos novos (sem remover os antigos):
   - hash_algo
   - hash_v
   - senha_hash_v2
2. Na escrita nova, grave somente o formato novo.
3. Na leitura/validacao (se houver), aceite legado por um periodo.
4. Rehash progressivo no primeiro evento do usuario.
5. Ao final, remova suporte legado.

## Exemplo de envelope de hash

{
  "hash_algo": "bcrypt",
  "hash_v": 2,
  "senha_hash_v2": "$2b$12$...",
  "criado_em": "timestamp"
}

## Regras de seguranca Firestore

- Garanta que os novos campos sejam permitidos em regras apenas onde necessario.
- Bloqueie update/delete de logs sensiveis para cliente comum.
- Mantenha leitura restrita a admin para colecoes de auditoria.

## Rotacao e higiene de segredos

- Se existir HMAC/pepper, guardar somente em backend/secret manager.
- Rotacionar chaves comprometidas antes de publicar.
- Nunca colocar segredo de servidor em .env do app cliente.

## Checklist final

- [ ] Auditoria concluida e distribuicao mapeada
- [ ] Politica de destino definida (Argon2id ou bcrypt)
- [ ] Escrita nova implementada
- [ ] Compatibilidade legado temporaria ativa
- [ ] Rehash progressivo concluido
- [ ] Campos legados desativados
- [ ] Regras revisadas
- [ ] Segredos em secret manager
