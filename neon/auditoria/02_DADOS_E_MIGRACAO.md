# SOFIA — Auditoria de dados, Neon, Supabase e estratégia de migração

**Data:** 02/11/2026  
**Escopo:** estrutura e preparação de dados. Nenhum dado real foi importado ou modificado.

## 1. Neon

Projeto existente `Sofia`, PostgreSQL 18, região São Paulo.

| Branch | Situação observada | Uso permitido nesta etapa |
|---|---|---|
| `production` | Sem tabelas públicas de aplicação na inspeção | Não alterar |
| `staging-migracao` | 43 tabelas, 314 colunas, 78 índices | Testes isolados e dados sintéticos |
 
As migrations 001 e 002 foram aplicadas em staging. Existem arquivos `.up.sql` e `.down.sql` correspondentes no diretório `neon/migrations`. Os testes SQL ficam em `neon/tests`.

O ledger preparado contempla contas, transações, lançamentos, função `ledger_apply`, chave de idempotência única, prevenção de saldo negativo e proteções de imutabilidade. A validação concorrente de 50 chamadas e 20 repetições simultâneas ainda não foi executada.

## 2. Supabase

- A conexão Supabase retornou um único projeto visível, com nome `Estrela da sorte`, região us-east-1.
- Não há confirmação do usuário de que esse projeto é o banco oficial do Sofia.
- `list_tables` e `execute_sql` expiraram por timeout em duas tentativas.
- Não foi possível confirmar DDL, quantidade de linhas, volume, chaves ou integridade referencial.
- A CLI local disponível falhou por módulo ausente (`MODULE_NOT_FOUND`); não foi usada para modificar qualquer projeto.

**Bloqueio:** não atribuir o projeto visível ao Sofia e não iniciar exportação/importação até confirmação explícita e acesso de leitura funcional.

## 3. Mapeamento do legado

O arquivo `neon/MAPEAMENTO.md` contém o mapeamento detalhado entre tabelas/coleções antigas e o esquema proposto. Regras essenciais:

- Preservar IDs opacos existentes como texto; não converter IDs sem necessidade.
- Não inventar saldos históricos.
- Importar transações para o ledger apenas quando houver contrapartida comprovada e conciliação possível.
- Guardar registros ambíguos em área de legado com origem e classificação pendente.
- Não misturar dados de teste e dados reais.
- Não colocar dados pessoais, chaves PIX ou segredos nos relatórios.
- Resolver duplicidades entre coleções `users` e `usuarios` antes de criar contas.

## 4. Fontes de dados legadas identificadas

- Backend: coleções JSON e fallback JSON, além de adaptador PostgreSQL.
- Painel: estado JSON separado em `admin_panel/data`.
- Directus: SQLite local.
- Supabase: projeto não confirmado e sem leitura SQL.
- Neon: staging preparado; produção sem tabelas públicas de aplicação na inspeção.

A coexistência dessas fontes impede declarar qual delas é a fonte operacional única para todos os dados.

## 5. Regras de migração propostas

1. Obter confirmação do banco oficial e acesso de leitura.
2. Fazer inventário DDL e contagem por tabela, sem copiar dados pessoais para relatórios.
3. Criar backup verificável e registrar checksums antes de qualquer importação.
4. Classificar dados sintéticos, demonstração e reais.
5. Preservar IDs e relações; registrar origem e chave antiga.
6. Conciliar saldos com extratos e operações de origem; não fabricar contrapartidas.
7. Importar primeiro em branch isolada, validar contagens, somatórios e invariantes.
8. Executar testes de idempotência, concorrência, rollback e reconciliação.
9. Somente depois solicitar autorização específica para qualquer janela de corte.

## 6. Lacunas de esquema conhecidas

Ainda faltam, ou precisam ser formalizadas no esquema:

- Restrição de exclusão GiST para impedir sobreposição de eventos.
- Rodadas/histórico de `lucky_hit` e endpoint correspondente.
- Turnos de administradores de sala.
- Assinaturas VIP/aristocracia.
- Duas mensagens gratuitas, cronômetro e tarifação de fotos/chamadas.
- Fluxo completo de saque via revenda, aceite, comprovante, pagamento e devolução de moedas.
- Pagamentos de ciclos/planilhas por pessoa.
- Limite diário e combos de sorte.
- Parâmetros de conversão 4 diamantes = 1 moeda e pacote US$ 0,99 = 16.830 moedas.
- Regras de bônus e faixas ainda não aprovadas.

Os valores de comissão de host (20–30%) e agência (4–20%) permanecem propostas, não regras finais confirmadas.

## 7. Artefatos existentes

- `neon/migrations/001_sofia_core.up.sql`
- `neon/migrations/001_sofia_core.down.sql`
- `neon/migrations/002_business_rule_guards.up.sql`
- `neon/migrations/002_business_rule_guards.down.sql`
- `neon/tests/001_ledger_core.sql`
- `neon/tests/002_business_rules.sql`
- `neon/MAPEAMENTO.md`
- `neon/README.md`

Nenhum arquivo SQL foi aplicado à branch Neon `production` durante esta auditoria.
