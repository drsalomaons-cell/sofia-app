# Lote 2 — staging Neon e preparação do adaptador backend

**Data:** 02/11/2026  
**Branch Git:** `staging/lote2-backend-neon`  
**Branch Neon:** `staging-lote2-2026-11-02` (`br-lingering-darkness-b6db5khv`)  
**Parent Neon:** `production` (`br-soft-butterfly-b67rmkr3`)

## 1. Backup e isolamento

- Backup remoto da `main`: `backup/lote2-main-2026-11-02`.
- Backup local dos refs Git e dos dois testes não rastreados: `D:\Backups\Sofia\Lote2-2026-11-02`.
- Bundle Git: `sofia-all-local-refs.bundle` (58,062,797 bytes); contém refs/commits locais.
- Os dois arquivos de teste locais foram copiados separadamente, pois arquivos não rastreados não entram no Git bundle.
- Branch backend criada a partir da `main`; nenhuma alteração foi feita na `main`.

## 2. Migrações executadas em Neon staging

As migrations 001 e 002 foram aplicadas exclusivamente em `staging-lote2-2026-11-02`, branch isolada derivada de `production`.

Validação estrutural posterior:
- 43 tabelas públicas.
- 314 colunas públicas.
- 78 índices públicos.
- A branch `production` foi consultada novamente e continua sem tabelas públicas de aplicação (`[]`).

Nenhuma tabela de produção foi alterada e nenhum dado real foi importado.

## 3. Testes financeiros executados

### 3.1 Ledger: 50 solicitações de débito

Foram submetidas 50 chamadas independentes a `ledger_apply`, em cinco lotes de dez chamadas paralelas, usando somente contas sintéticas:
- Saldo inicial: 100 unidades.
- Débito por chamada: 10 unidades.
- Resultado: 10 chamadas confirmadas; 40 rejeitadas por saldo insuficiente.
- Saldo final: 0.
- Transações de ledger criadas para o teste: 10.

**Limite do teste:** o limite de concorrência foi 10 chamadas paralelas por lote, não 50 sessões simultâneas. Portanto, isto valida 50 tentativas em cinco ondas e concorrência de até 10, não uma carga de 50 conexões simultâneas.

### 3.2 Idempotência: 20 chamadas com a mesma chave

Foram submetidas 20 chamadas com payload e chave idênticos, em duas ondas de dez:
- 20 chamadas retornaram sucesso.
- Todas retornaram o mesmo UUID de transação.
- Uma única linha de transação foi gravada.
- Duas entradas de ledger foram gravadas (débito/crédito).
- Saldo da conta sintética: 1.000 → 990.

O resultado confirma idempotência repetida e concorrente em grupos de até dez chamadas.

### 3.3 Latência de consulta

Uma consulta simples por carteira foi analisada com `EXPLAIN ANALYZE`:
- Planning Time: 0,066 ms.
- Execution Time: 0,038 ms.
- Plano: Seq Scan, removendo 7 linhas.

A tabela de teste tinha somente 8 contas. O Seq Scan é esperado nesse volume e não justifica criar índice adicional. Esses números medem execução dentro do PostgreSQL, não latência HTTP, rede, API ou experiência do aplicativo. Não são benchmark de produção.

## 4. Adaptador backend isolado

Foi adicionado `backend/services/neon-ledger.js`, um adaptador pequeno e parametrizado que invoca a função `ledger_apply` do esquema consolidado. O adaptador recebe um Pool `pg` existente e não cria conexão nem altera variáveis de ambiente.

Foram adicionados testes unitários para:
- Consulta parametrizada e retorno do ID da transação.
- Validação de chave, tipo, movimentos, IDs duplicados e valores inteiros.
- Propagação de falhas do banco.
- Validação do Pool.

Execução no worktree isolado `D:\\Workspace\\Sofia\\Lote2Backend`:
- Comando: `node --test test\\neon-ledger.test.js test\\withdrawal.test.js`.
- Resultado: 7 testes passaram, 0 falharam (4 do adaptador + 3 de saque existentes).
- Worktree terminou limpo; a cópia original `D:\\Workspace\\Sofia\\source` manteve os dois testes não rastreados intactos.

## 5. Bloqueio de integração identificado

**Não é seguro apontar o backend legado diretamente para esta branch Neon.**

O backend atual executa `backend/db/postgres.js`, que ao iniciar lê e executa `backend/db/schema.sql`. O store legado espera colunas JSONB `data` em tabelas como `users`, `rooms` e `transactions`. O esquema consolidado 001/002 define essas entidades em colunas normalizadas e não contém o contrato JSONB legado.

Além disso, `backend/data/store.js` mantém cache e fallback em JSON. Conectar o backend atual à branch Neon sem uma camada de repositório e migração funcional provocaria incompatibilidade de esquema e risco de perda/inconsistência de dados.

Por isso, o adaptador foi deixado isolado e não foi ligado ao servidor, ao painel, ao Render ou ao fluxo de carteira. A integração exige uma etapa própria de reescrita dos repositórios e testes ponta a ponta.

## 6. Ações não executadas

- Nenhuma alteração de `.env` ou `DATABASE_URL`.
- Nenhum deploy Render.
- Nenhum merge ou push para `main`.
- Nenhuma importação de dados reais.
- Nenhum teste de pagamento ou saque com provedor real.
- Nenhuma alteração no Neon `production`.
