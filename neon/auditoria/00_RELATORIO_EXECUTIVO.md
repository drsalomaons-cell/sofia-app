# SOFIA — Relatório executivo da Auditoria do Lote 1

**Data do registro:** 02/11/2026  
**Escopo:** inventário, auditoria estática do código, infraestrutura, dados, segurança e regras econômico-financeiras.  
**Natureza:** diagnóstico; nenhuma alteração em produção, deploy, serviço Render, projeto Supabase ou banco Neon foi executada nesta rodada.

## 1. Conclusão executiva

O projeto possui uma base funcional em Flutter e serviços Node, mas **não está pronto para tratar saldos, recargas e saques como operações financeiras confiáveis em produção**. Os principais bloqueios são a existência de múltiplas fontes de persistência, operações de saldo não atômicas, ausência de idempotência persistente em fluxos críticos, autenticação/autorização insuficiente em rotas e sockets, e divergência entre as regras econômicas solicitadas e os valores padrão do legado.

O serviço Render `sofia-app` está **ativo e não suspenso**, mas executa uma versão antiga do código e os logs consultados indicam fallback para armazenamento JSON. A conexão operacional do serviço com Neon não foi comprovada.

O branch Neon `staging-migracao` contém o esquema de preparação e as migrations 001/002. A branch Neon `production` permaneceu sem alterações. O esquema de staging não deve ser tratado como autorização para importar dados reais.

O Supabase oficial do Sofia continua **não identificado**. O único projeto visível na conexão Supabase tem nome `Estrela da sorte`; o usuário ainda não confirmou que esse projeto pertence ao Sofia. As consultas SQL falharam por timeout, portanto não há inventário confiável de tabelas ou contagens.

## 2. Achados de maior prioridade

| Prioridade | Achado | Consequência |
|---|---|---|
| Crítica | Arquivo raiz `.env` listado como asset do Flutter | Segredos de servidor podem ser incluídos no APK |
| Crítica | Recarga aceita valor informado pelo cliente e possui caminho simulado/sandbox | Possibilidade de crédito sem confirmação robusta do provedor |
| Crítica | Ganho de sala aceita `totalAmount` do cliente | Cliente pode influenciar cálculo financeiro |
| Crítica | Emissão de token ZEGO sem autenticação suficiente | Emissão indevida de credenciais de sessão |
| Alta | Webhook PagBank sem deduplicação persistente antes do crédito | Reprocessamento pode duplicar crédito |
| Alta | Saques com idempotência em memória e sem bloqueio transacional persistente | Corrida entre instâncias e solicitações duplicadas |
| Alta | Scheduler pode concluir saque com base em tempo, sem prova de pagamento | Status pode indicar pagamento não comprovado |
| Alta | Múltiplas fontes de verdade: JSON, PostgreSQL, painel JSON e Directus SQLite | Divergência de saldo, cadastro e configuração |
| Alta | Render ativo com fallback JSON nos logs | Persistência operacional no banco não comprovada |
| Alta | CORS amplo e autorização insuficiente em rotas/socket | Exposição a ações não autorizadas |

## 3. Infraestrutura e dados

- Render: serviço `sofia-app` ativo, uma instância, plano Free, região Virginia, root directory `admin_panel`; não suspenso.
- Render: serviço `sofia-painel` também não está suspenso, porém deploys recentes falharam. A configuração aponta para raiz do repositório, onde a branch consultada não contém `package.json` nem `server.js`; isso é uma causa provável, ainda não confirmada por log de build.
- Neon: projeto existente `Sofia`, região São Paulo, PostgreSQL 18, plano Free. Branch `production` sem tabelas públicas de aplicação; branch `staging-migracao` contém 43 tabelas, 314 colunas e 78 índices.
- Supabase: projeto visível não confirmado como Sofia e consultas SQL indisponíveis por timeout.
- Directus: configuração consultada utiliza SQLite local; não foi comprovada integração com o banco Neon.
- Git: branch local de trabalho tinha dois arquivos de teste não rastreados; não foram alterados. Uma segunda cópia local tinha arquivos gerados modificados; não foi tocada.

## 4. Testes realizados e limites

- `node --test backend/test/withdrawal.test.js`: 3/3 testes passaram.
- Reprodução isolada de corrida de saque: duas instâncias simuladas com cache de saldo desatualizado processaram duas solicitações de 80 sobre saldo inicial 100. Houve duas chamadas simuladas ao provedor; uma resposta 200 e outra 500; saldo final local 20; uma transação concluída e outra pendente.
- A reprodução não chamou PagBank real e não representa incidente observado em produção.
- Não foram executados testes no banco de produção, teste de 50 concorrentes, importação de dados, deploy ou teste ponta a ponta de pagamento real.

## 5. Decisão recomendada

1. Não ativar recargas, saques ou recompensas reais com a implementação atual sem correções e testes de integração.
2. Remover o `.env` do bundle Flutter e separar configuração pública de segredos do servidor; avaliar rotação de segredos se algum APK contendo esses valores tiver sido distribuído.
3. Definir uma única fonte de verdade para saldo e transações, com ledger append-only, transações SQL e chaves de idempotência persistentes.
4. Confirmar formalmente qual projeto Supabase, se houver, pertence ao Sofia.
5. Corrigir a configuração do serviço Render `sofia-painel` e comprovar a conexão do serviço ativo com o banco escolhido.
6. Completar regras e tabelas ausentes antes de importar dados reais.

## 6. Limites desta entrega

Este relatório consolida evidências observadas na auditoria, não certifica conformidade regulatória, segurança completa, disponibilidade, nem integridade de dados históricos. Achados devem ser validados em ambiente controlado antes de qualquer mudança.

**Lote 1 encerrado nesta entrega. Nenhuma atividade do Lote 2 foi iniciada.**
