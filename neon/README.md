# SOFIA — preparação Neon (isolada)

- Projeto Neon existente: `Sofia`.
- Banco de produção: branch `production`; não aplicar migrations nele.
- Branch de testes: `staging-migracao`.
- Branch de código: `audit/neon-prep`.
- Migração inicial: `migrations/001_sofia_core.up.sql`; rollback correspondente em `migrations/001_sofia_core.down.sql`.
- Aplicar somente em branch isolado; migrations usam PostgreSQL 18.
- Não inserir dados reais durante a Rodada 1.
- Todos os valores monetários são inteiros em unidades mínimas (centavos ou unidades inteiras de moeda virtual).
- O livro-razão é append-only; movimentações devem passar por `ledger_apply()`.
- O arquivo `tests/001_ledger_core.sql` prepara contas sintéticas e valida idempotência sequencial, saldo não negativo, equilíbrio por moeda e imutabilidade. A concorrência real (50 chamadas simultâneas e 20 repetições simultâneas) é executada separadamente e registrada no relatório.
- Nenhuma URL de conexão, senha, token ou chave deve ser armazenada nestes arquivos.
