# Auditoria e correção — login/cadastro Sofia

## Causa encontrada
O aplicativo Flutter chama `/api/auth/register`, `/api/auth/login` e `/api/auth/me/:id`. O servidor principal que servia o painel administrativo não montava as rotas móveis; por isso o serviço publicado respondia 404 ao endpoint de verificação usado para confirmar a API.

## Correções
- O servidor do painel agora inicializa o armazenamento e registra as rotas da API móvel.
- O servidor passou a respeitar `process.env.PORT`, necessário em hospedagem gerenciada.
- A API de salas e o Socket.IO foram ligados ao mesmo servidor HTTP.
- O backend é instalado durante o `postinstall` do painel, para que as dependências de `backend/` também existam no deploy.
- O cliente Flutter usa o domínio Render conhecido como fallback, em vez do IP local antigo.
- Os endpoints de branding/capas agora usam a URL-base configurada do cliente.

## Testes executados localmente
- `node --check` em `admin_panel/server.js`, `backend/server.js` e `backend/socket/rooms.js`: passou.
- Fluxo HTTP temporário de cadastro → login → restauração de sessão: passou.
- Handshake Socket.IO: HTTP 200 e SID recebido.
- `flutter test --no-pub`: passou.
- `flutter build apk --debug --no-pub`: passou; APK de teste guardado fora do clone em `../Builds/Sofia-debug.apk` (não versionar o APK).
- `npm audit` no painel: zero vulnerabilidades após atualizar `sharp` e `node-cron` no painel.
- `node-cron` do backend foi atualizado para 4.6.0; a inicialização e o fluxo de autenticação foram testados novamente.

## Limites da validação
- Os testes HTTP foram feitos contra o servidor local, não contra o deploy remoto após publicação.
- Nenhum Android está conectado por ADB nesta sessão; a instalação e a interface em aparelho físico ainda não foram verificadas.
- Para persistência de contas em produção, o serviço hospedado deve ter `DATABASE_URL` configurada para PostgreSQL. Sem ela, o backend usa JSON local.
- O APK debug depende da URL presente em `.env`; para testar via Render, `API_URL_LOCAL` deve apontar para o domínio publicado. Nunca colocar segredos de servidor dentro do APK.