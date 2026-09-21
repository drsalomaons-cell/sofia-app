# Directus SOFIA

## Inicializacao

1. Copie `.env.example` para `.env` e preencha os valores reais. Nao use as senhas de exemplo.
2. Garanta que o PostgreSQL esteja acessivel pelo host configurado.
3. O backend aplica `backend/db/schema.sql` na inicializacao e cria as sete colecoes administrativas.
4. Suba o painel:

```powershell
docker compose up -d
```

Acesse `http://localhost:8055` e entre com `DIRECTUS_ADMIN_EMAIL`/`DIRECTUS_ADMIN_PASSWORD`.

## Permissoes obrigatorias

Crie dois roles no Directus, `ADM CENTRAL` e `ADM REGIONAL`, e adicione `regiao` aos usuarios do Directus.

- Central: leitura/escrita nas sete colecoes; `logs_auditoria` somente leitura; pode criar e desativar administradores.
- Regional: em `usuarios`, escrita somente em `nome_usuario`, `bio` e `url_imagem_perfil`, com filtro `regiao = $CURRENT_USER.regiao`; `saldo_moedas`, `email`, `regiao` e `status` ficam somente leitura.
- Regional: em `salas_agencias`, escrita somente em `nome`, `url_imagem` e `descricao`, com filtro `regiao = $CURRENT_USER.regiao`.
- Regional: leitura de `solicitacoes_moedas` pela relação `usuario_id.regiao = $CURRENT_USER.regiao` e leitura de `mensagens` quando remetente ou destinatário pertence à região.
- Regional: criação de `conteudo_moderacao` para sinalização, sem poder alterar `revisado_por`, `data_revisao` ou `status`.
- Regional: remova a permissao de alterar `status`, `quantidade_liberada`, `aprovado_por` e `data_aprovacao`.
- Regional: nenhuma permissao em `administradores` fora do proprio registro, `logs_auditoria` ou recuperacao de mensagens.
- Ambos: remova update/delete de `logs_auditoria` para todos os roles.

A aprovacao deve ser feita pelo Flow do Directus usando `status = aprovada`, `quantidade_liberada` e `aprovado_por`. O trigger PostgreSQL atualiza `usuarios.saldo_moedas`, grava `logs_auditoria`, preenche a data e impede liberar mais que o solicitado. O toggle de solicitações de teste está em `configuracao_solicitacoes_moedas.habilitado`; o Flow deve recusar novas solicitações quando estiver desabilitado e permanecer desativado em producao quando o modo de teste não for necessário.