# Mapeamento do legado para o esquema consolidado SOFIA

**Escopo:** mapeamento estrutural do repositório `main` (arquivo `backend/db/schema.sql` e coleções JSON). Não representa uma migração de dados e não identifica o Supabase oficial: a conexão Supabase disponível expirou em timeout e o projeto visível não foi confirmado pelo usuário como o do Sofia.

## Regras de preservação

- IDs existentes serão preservados como `users.id TEXT` e `rooms.id TEXT`; não converter IDs opacos para UUID.
- Nenhum saldo histórico será inventado. Só criar lançamentos de livro-razão quando existir informação suficiente para reconstruir os dois lados da operação.
- Registros sem classificação ficam em `legacy_import_records` com o JSON original, origem, chave antiga e classificação pendente.
- Não misturar registros de teste e reais. A classificação deve ser validada antes da importação.
- Dados pessoais e chaves PIX não entram em relatórios. Chaves PIX, se necessárias, devem ser criptografadas fora do banco antes de gravar em `withdrawal_requests.pix_key_ciphertext`.

## Mapeamento das tabelas PostgreSQL antigas

| Origem | Destino proposto | Observação |
|---|---|---|
| `users` | `users` + `user_profiles` + `wallets` + `ledger_accounts` | Extrair campos JSON; preservar ID. Criar contas somente após conciliação dos saldos. |
| `rooms` | `rooms` + `room_seats` + `room_memberships` | JSON de sala exige normalização de cadeiras e participantes. |
| `transactions` | `legacy_import_records`; depois `ledger_transactions` + `ledger_entries` quando conciliável | Não transformar cada linha isolada em lançamento balanceado sem contrapartida comprovada. |
| `gift_catalog` | `store_items` + `store_item_prices` + `gift_catalog` | Separar preços por tipo de moeda. |
| `gift_log` | `gift_transfers` e/ou `legacy_import_records` | Validar remetente, destinatário, sala, valor e transação correspondente. |
| `economy_config` | `economy_settings` | Converter configuração com revisão das regras vigentes. |
| `pending_payments` | `payments` + `payment_webhook_events` | Preservar IDs externos e status; deduplicar webhooks. |
| `job_runs` | `job_runs` | Mapeamento direto, após validar nomes e formato de dados. |
| `administradores` | `users` + `user_profiles` + `user_roles` | Hash de senha não deve ser reusado sem auditoria do algoritmo. |
| `usuarios` | `users` + `user_profiles` + `wallets` + `ledger_accounts` | Conciliar com `users`; não criar usuários duplicados por e-mail sem resolução. |
| `salas_agencias` | `agencies` ou `rooms` | **Ambíguo pelo DDL atual**; classificar registro por registro antes de importar. |
| `solicitacoes_moedas` | `coin_release_requests` | Aprovação e crédito devem gerar transação financeira idempotente. |
| `mensagens` | `messages` | Preservar IDs e timestamps; aplicar política de privacidade e retenção. |
| `logs_auditoria` | `audit_logs` | Imutabilidade no destino; não copiar IP/dados pessoais para relatórios. |
| `conteudo_moderacao` | `moderation_cases` | Preservar status e trilha de revisão. |
| `configuracao_solicitacoes_moedas` | `economy_settings` | Mapear habilitação e auditoria de alteração. |

## Mapeamento das coleções JSON

| Coleção | Destino proposto |
|---|---|
| `users.json` | `users`, `user_profiles`, `wallets`, `ledger_accounts`; saldos só após conciliação |
| `rooms.json` | `rooms`, `room_seats`, `room_memberships` |
| `transactions.json` | `legacy_import_records`; ledger somente após conciliação |
| `gift_catalog.json` | `store_items`, `store_item_prices`, `gift_catalog` |
| `gift_log.json` | `gift_transfers` / `legacy_import_records` |
| `economy_config.json` | `economy_settings` |
| `admin_panel/data/admin-state.json` | `users`, `user_profiles`, `user_roles`, `audit_logs`, `coin_release_requests`, `moderation_cases`, `messages`; requer revisão de hash e credenciais padrão |

## Pontos que bloqueiam migração de dados

1. Projeto Supabase oficial do Sofia ainda não foi identificado. A conta conectada mostrou apenas um projeto visível e as consultas SQL expiraram.
2. Não há confirmação de contagens de linhas, tamanho de tabelas nem DDL do Supabase.
3. `salas_agencias` mistura nomenclatura de sala/agência e precisa de classificação.
4. O legado guarda muitas entidades em JSONB; é necessário inventário de chaves e conciliação antes de normalizar.
5. O back-end ativo no Render ainda executa um commit antigo e registra fallback para JSON. Não apontar para Neon até resolver deploy, credenciais e plano de migração.
