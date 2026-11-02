# SOFIA — Inventário de infraestrutura, GitHub e Render

**Data:** 02/11/2026  
**Escopo:** leitura de configuração e estado de serviços; sem deploy ou alteração de configuração.

## 1. Render

### Serviço `sofia-app`

- Estado retornado: `not_suspended`; `maintenanceMode=false`.
- Instâncias: 1; plano Free; região Virginia.
- Root directory: `admin_panel`.
- Build command: `npm install`.
- Start command: `node server.js`.
- O servidor do painel importa módulos do diretório `backend`.
- Deploy ativo observado: commit `4903d22007b7f8b1ef463df7be0052cb82c53074`, de 11/10/2026, anterior ao código atual consultado em `main`.
- Logs recentes registraram fallback para JSON local e orientação para definir `DATABASE_URL`. Isso não comprova conexão operacional com Neon.
- Não há `healthCheckPath` configurado.

**Conclusão:** o serviço está ativo, não suspenso. A versão em execução está defasada em relação ao código consultado e a persistência PostgreSQL não foi comprovada.

### Serviço `sofia-painel`

- Estado retornado: `not_suspended`; portanto, não deve ser descrito como suspenso.
- Deploys recentes retornaram falha.
- Root directory vazio; build `npm install`; start `node server.js`.
- Na branch `main` consultada, a raiz não contém `package.json` nem `server.js`.
- Essa incompatibilidade é uma causa provável para falha, mas os logs completos do build não foram obtidos para confirmar o motivo exato.

### Outros pontos

- Não foi identificado banco PostgreSQL provisionado no Render.
- Não houve alteração de variáveis de ambiente, serviços, instâncias, planos, domínio ou deploy.
- Serviços continuam configurados para deploy automático a partir de `main`.

## 2. Neon

- Projeto: `Sofia`; região `aws-sa-east-1` (São Paulo); PostgreSQL 18; plano Free.
- Branch `production`: sem tabelas públicas de aplicação na inspeção.
- Branch `staging-migracao`: 43 tabelas, 314 colunas, 78 índices.
- Branch GitHub `audit/neon-prep` já contém migrations 001/002 e testes SQL.
- A branch de documentação deste Lote 1 é `audit/lote1-master`, criada a partir de `audit/neon-prep`.
- Nenhuma migration foi aplicada em `production`; nenhuma importação de dados reais foi realizada.

## 3. GitHub e cópias locais

- Repositório: `drsalomaons-cell/sofia-app`.
- Branch local observada: `fase2-visual-sorte`, commit `89a03b74bbc19a899f3bdc29bf653113fa09d2f2`.
- Branch `main` observada: commit `64c54270e8ba0c14e9f14a433a87b6df893dcdd7`.
- A branch local `fase2-visual-sorte` estava 7 commits à frente de `main` na auditoria anterior.
- Dois arquivos de teste estavam não rastreados: `test/living_frame_library_test.dart` e `test/lucky_hit_button_test.dart`. Foram preservados sem edição.
- A cópia `D:\SofiaGitHubAudit` continha arquivos gerados Flutter modificados; não foi alterada.
- Não foi feito checkout, reset, limpeza, commit local ou push para `main`.

## 4. Outras fontes de persistência

- Backend contém persistência JSON com fallback e implementação PostgreSQL.
- Painel administrativo possui arquivos JSON próprios em `admin_panel/data`.
- Directus está configurado com SQLite em `directus/database/data.db`.
- Essa fragmentação cria risco de divergência de cadastros, saldos, configurações e auditoria.

## 5. Ações recomendadas (não executadas)

1. Corrigir a configuração do serviço `sofia-painel` para apontar para o diretório e comandos reais do painel, após validar com build isolado.
2. Atualizar o serviço ativo somente após validar a branch, dependências, variáveis e conexão de banco em staging.
3. Adicionar health check real e monitoramento de persistência.
4. Definir formalmente a fonte única de verdade e plano de descontinuação dos armazenamentos JSON/SQLite.
5. Não realizar deploy nem corte de produção sem autorização escrita e janela de mudança.
