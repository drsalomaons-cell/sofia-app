# SOFIA — Auditoria de segurança e privacidade

**Data:** 02/11/2026  
**Método:** inspeção estática de arquivos e configuração. Não é pentest, não houve exploração contra produção e nenhum segredo foi exibido.

## 1. Achados críticos

### 1.1 Segredos de servidor declarados como asset Flutter

O `pubspec.yaml` lista o arquivo raiz `.env` como asset Flutter. A inspeção confirmou que esse arquivo contém nomes de variáveis de servidor, incluindo `ADMIN_CENTRAL_PASSWORD`, `JWT_SECRET`, `ZEGO_SERVER_SECRET` e `SOFIA_CLIENT_TOKEN`. Os valores não foram lidos nem reproduzidos neste relatório.

**Risco:** qualquer segredo incluído no bundle pode ser extraído de um APK distribuído. Segredos de servidor nunca devem ser entregues ao cliente móvel.

**Correção recomendada:** remover o arquivo de servidor da lista de assets; criar configuração pública separada e restrita ao que o aplicativo precisa; manter segredos apenas no ambiente do servidor. Se um APK contendo esses valores já foi distribuído, avaliar rotação coordenada de credenciais. Nenhuma dessas ações foi executada.

### 1.2 Recarga e confirmação de pagamento

- A rota de recarga recebe valor informado pelo cliente.
- O serviço PagBank possui caminhos simulados quando não há credencial/configuração operacional.
- O resultado sandbox pode seguir fluxo que credita saldo.
- O webhook não apresenta deduplicação persistente antes do crédito.

**Risco:** crédito sem confirmação independente, valor arbitrário ou crédito duplicado por reenvio de webhook.

### 1.3 Autorização e emissão de tokens

- Emissão de token ZEGO sem autenticação suficiente.
- Rota de banimento de sala sem autorização adequada.
- Rotas administrativas e estatísticas precisam de revisão de escopo e controle por função.
- Ações Socket.IO de conexão, entrada, presentes e RTC não demonstram autenticação e autorização robustas em todos os caminhos examinados.

## 2. Achados altos

- CORS amplo no backend e no painel.
- Sessões administrativas mantidas em memória, sem TTL/expiração comprovada.
- Ausência de rate limiting de login e de segundo fator no painel examinado.
- Senha administrativa padrão `123456` e aceitação de credencial legada em texto simples.
- Hash SHA-256 simples no painel; não equivale a um KDF apropriado para senhas.
- Scrypt existe no módulo de autenticação, mas há fallback legado de senha em texto simples.
- JWT com validade de 7 dias e sem mecanismo de revogação identificado.
- Dados pessoais podem ser incluídos em respostas de perfil público; o helper remove hash/senha, mas pode devolver e-mail, telefone e outros campos.
- Arquivos JSON administrativos estão rastreados no repositório público. Não foram abertos nem copiados por conterem potencialmente dados pessoais.

## 3. Persistência e integridade

- O adaptador PostgreSQL substitui conteúdo de coleções por operações DELETE/reinsert dentro de transação, mas fluxos financeiros chamam persistência em etapas distintas.
- Algumas chamadas de persistência não são aguardadas explicitamente.
- Não existe ledger financeiro único e obrigatório no fluxo legado.
- Idempotência de saque baseada em memória não protege contra reinício ou múltiplas instâncias.
- Scheduler pode marcar saque como concluído com base em tempo decorrido, sem evidência de pagamento do provedor.

## 4. Controles recomendados

1. Tratar todos os segredos de servidor como comprometíveis se foram empacotados em APK distribuído; planejar rotação sem interromper produção.
2. Remover `.env` do bundle e criar verificação automatizada para impedir inclusão futura.
3. Exigir autenticação, autorização por função, escopo de sala e validação de propriedade em todas as rotas e eventos Socket.IO.
4. Validar pagamento exclusivamente por confirmação autenticada do provedor; nunca confiar em preço/valor enviado pelo cliente.
5. Persistir idempotência em banco com chave única e transação atômica.
6. Implementar controle de sessão, expiração, revogação, rate limit, MFA para administradores e hash de senha com algoritmo apropriado.
7. Aplicar minimização de dados pessoais em APIs e logs.
8. Remover arquivos de dados locais do versionamento em mudança controlada, preservando cópias e verificando impacto antes.
9. Restringir CORS aos domínios necessários.
10. Criar testes automatizados de autorização negativa e abuso de fluxo.

## 5. Limitações

A auditoria foi estática e limitada aos arquivos lidos. Não certifica ausência de outras vulnerabilidades, não substitui análise de dependências, SAST/DAST, pentest, revisão de infraestrutura ou validação legal LGPD. Nenhuma correção foi aplicada nesta etapa.
