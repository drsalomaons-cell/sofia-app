# SOFIA — Auditoria econômico-financeira e testes

**Data:** 02/11/2026  
**Escopo:** regras de carteira, pagamentos, presentes, saques, concorrência e testes. Valores de regras ainda não aprovadas são identificados como pendentes.

## 1. Divergência entre regras de negócio e defaults do legado

O módulo de economia legado contém valores padrão hardcoded (por exemplo, divisão 50/50, conversão 1:1 e taxa de 5%) que divergem das regras mais recentes fornecidas para o produto. Não se deve presumir que os defaults do código representam a política vigente.

### Parâmetros já registrados no esquema de staging

- BD: 1%.
- ADM oficial: 1%.
- Super ADM: 2%.
- Salário BD/ADM oficial: US$ 100.
- Salário Super ADM: US$ 300–500.
- Saque mínimo: R$ 10.
- Cotação de referência para revenda/saque: R$ 5,80 por US$ 1.
- Revendedor ativo: compra mínima de US$ 50.
- Primeira compra para habilitar revendedor: US$ 500.
- Presente da sorte: retenção da plataforma de 70%; idade mínima de 18 anos.

Esses parâmetros estão registrados como configuração/seeds no staging; precisam de validação funcional e contratual antes de uso financeiro real.

### Regras pendentes de formalização

- Host: faixa de 20–30% (proposta).
- Agência: faixa de 4–20% (proposta).
- Conversão: 4 diamantes = 1 moeda.
- Pacote: US$ 0,99 = 16.830 moedas.
- Bônus, metas, faixas e comissões por ciclo.
- Limite diário e combos do jogo da sorte.
- Critérios de saque, aceite da revenda, comprovante, confirmação de pagamento e devolução de moedas em caso de recusa.

Não transformar faixas propostas em valores definitivos sem aprovação expressa.

## 2. Fluxos críticos observados no código

### Recarga

A API aceita valor do cliente e o serviço de pagamento possui caminho simulado/sandbox. O backend precisa determinar pacote, preço e moeda a partir de catálogo imutável no servidor e creditar somente após evento autenticado e confirmado pelo provedor.

### Ganhos de sala

A rota examinada recebe `totalAmount` do cliente. O servidor deve calcular integralmente valores, taxas, cotas e saldos usando dados persistidos e regras versionadas.

### Presentes

O catálogo de preços é obtido do servidor, o que é positivo. Entretanto, o débito/crédito não está integrado atomicamente ao ledger nem protegido por idempotência persistente.

### Saques

A idempotência está baseada em memória. Não há bloqueio persistente da carteira e unicidade transacional demonstrada. O scheduler pode alterar status sem confirmação do provedor.

## 3. Reprodução de concorrência de saque

Foi criado um teste de reprodução fora do repositório, em ambiente isolado, sem chamar provedor real:

- Saldo inicial simulado: 100.
- Duas instâncias independentes com cache desatualizado.
- Duas solicitações concorrentes de 80.
- Resultado: duas chamadas simuladas ao provedor foram aceitas; uma resposta HTTP 200 e outra HTTP 500; saldo final local 20; uma transação concluída e outra pendente.

O teste demonstra que o desenho legado pode permitir corrida sob caches/instâncias independentes. **Não comprova incidente ocorrido em produção**. O serviço Render observado tinha uma instância; o teste é uma reprodução de risco arquitetural, não medição do ambiente produtivo atual.

## 4. Testes executados

| Teste | Resultado | Observação |
|---|---:|---|
| `node --test backend/test/withdrawal.test.js` | 3/3 passaram | Testes unitários existentes |
| Reprodução isolada de corrida | Reproduzida | Sem PagBank real e sem banco de produção |
| Teste concorrente de 50 operações | Não executado | Pendente |
| 20 repetições idempotentes simultâneas | Não executado | Pendente |
| Integração PagBank real | Não executada | Sem operação financeira real |
| Testes de ledger em staging | Testes SQL existentes; cobertura parcial anterior | Não equivalem a carga concorrente completa |
| Teste ponta a ponta em produção | Não executado | Proibido nesta etapa |

## 5. Requisitos mínimos antes de dinheiro real

1. Um ledger append-only como única fonte de saldo.
2. Débito e crédito na mesma transação SQL, com bloqueio de linha ou mecanismo equivalente.
3. Chave de idempotência persistente e única para cada operação externa/interna.
4. Webhook autenticado, deduplicado e armazenado antes de produzir crédito.
5. Preço, moeda, taxa e comissão calculados no servidor com regras versionadas.
6. Saque só pode ser concluído com confirmação verificável de pagamento.
7. Estados explícitos de saque: solicitado, reservado, aceito, pago, recusado, cancelado e estornado, com transições auditáveis.
8. Reconciliação diária entre ledger, provedor, revenda e carteiras.
9. Testes de concorrência com múltiplas conexões e transações reais em staging.
10. Testes de falha/retry, duplicação, timeout, rollback e recuperação após reinício.

## 6. Escopo não executado

Nenhum saldo foi alterado, nenhum pagamento real foi iniciado, nenhum saque foi pago e nenhum parâmetro de produção foi modificado. Este relatório não representa aprovação contábil, financeira ou jurídica das regras de negócio.
