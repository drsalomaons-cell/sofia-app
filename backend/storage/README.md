# Capas Criptografadas SOFIA

## Estrutura
- `encrypted_covers/capa1.enc` — Luz e Pureza
- `encrypted_covers/capa2.enc` — Brilho e Graça
- `encrypted_covers/capa3.enc` — Delicadeza e Harmonia

## Como inserir novas imagens (SVG)
1. Faça login no Painel Admin: http://localhost:3000/admin
2. Vá em **Configurações → Aparência → Selecionar Capa Ativa**
3. Ou envie via API (admin):

```
POST /api/covers/capa1/upload
Authorization: Bearer sofia-admin-token
Content-Type: application/json

{ "content": "<svg>...</svg>" }
```

## Segurança
- Arquivos `.enc` usam AES-256-GCM
- Chave: variável `BRANDING_PROTECTION_KEY` no `.env`
- Acesso público direto bloqueado — apenas rota autorizada:
  `GET /api/covers/:id/content` (header `X-Sofia-Client: sofia-app-v1`)

## Quando você enviar as 3 imagens finais
Substituiremos os placeholders via upload criptografado e confirmaremos no app.
