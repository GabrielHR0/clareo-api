# Clareo — Visão Geral

> Plataforma SaaS de captação de doações para instituições de terceiros, com
> rateio automático via split e repasse por Pix.

## O Problema

Instituições de caridade, ONGs e criadores de conteúdo captam doações hoje com
plataformas que cobram de 10% a 15% por doação e entregam o dinheiro em dias.

Do ponto de vista da instituição:

- Taxa alta e variável, sem previsão
- Dinheiro parado em conta corrente, sem qualquer rendimento
- Pouca rastreabilidade entre a doação e quem recebeu
- Nada que funcione para quem não tem CNPJ

## A Solução

O **Clareo** é uma plataforma SaaS que intermedeia a doação em BRL e a repassa
à instituição:

1. A instituição se cadastra na Clareo e-connecta à plataforma
2. O doador paga por Pix, boleto ou cartão
3. No recebimento, o Asaas repassa a parcela da instituição direto para a
   subconta dela, e retém a taxa da plataforma
4. A instituição saca quando quiser, por Pix ou TED

## Modelo de Receita

| Fonte | Descrição |
|-------|-----------|
| **Split por doação** | Percentual retido pela Clareo, definido por faixas de valor |
| **Assinatura SaaS** | Plano mensal da instituição, com limite de instituições |

O plano **não** define a taxa de split anymore. A taxa vem de uma política
global por faixas, configurável — ver [11-CUSTOS-RECEITAS.md](11-CUSTOS-RECEITAS.md).

## Por que Asaas e não outro provedor

O Asaas é uma **instituição de pagamento autorizada pelo Banco Central** (código
461) e oferece o que o modelo exige e concorrentes não:

| Necessidade | Asaas oferece |
|-------------|---------------|
| Subcontas por instituição | `POST /v3/accounts`, com `walletId` próprio |
| Rateio na própria cobrança | Campo `split` em `POST /v3/payments` |
| Sem custódia de cripto pela plataforma | Dinheiro é gerido pela instituição de pagamento |
| Saque para a instituição | Pix e TED a partir da subconta |

## Posição Regulatória

O Clareo **não custodia recursos de terceiros**. A custódia é do Asaas, que é
instituição de pagamento regulada. O Clareo opera como fornecedor de tecnologia
(SaaS), intermedeando a relação comercial entre instituição e instituição de
pagamento.

Isso é uma mudança material em relação ao modelo anterior, descrito em
[_arquivados/README.md](_arquivados/README.md), em que a plataforma segurava
chaves privadas de TRON e conversava USDT — uma posição regulatória de risco
elevado.

## Os Dois Caminhos de Liquidação

O provedor só cria subcontas para **pessoa jurídica com CNPJ** (Resoluções
Conjuntas 16 e 17 do Banco Central). Como parte relevante do público-alvo é
pessoa física, o Clareo tem dois caminhos:

```
Instituição COM CNPJ (:subaccount)          Instituição SEM CNPJ (:pix_payout)
──────────────────────────────────────      ──────────────────────────────────────
Cobrança COM splits[]                        Cobrança SEM splits[]
  → subconta recebe a parcela dela             → Clareo recebe 100% do líquido
  → Clareo retém o restante                    → split fica só como registro contábil
Instituição saca direto no Asaas             Clareo paga por Pix depois
```

Em ambos os casos a instituição tem direito à mesma parcela defined pela
`SplitPolicy`. O que muda é o mecanismo, não a economia.

## Público-Alvo

- Instituições de caridade e ONGs (com CNPJ)
- Criadores de conteúdo e influenciadores (com ou sem CNPJ)
- Projetos comunitários
- Startups de impacto social

## Stack Tecnológica

| Camada | Tecnologia |
|--------|------------|
| Backend | Ruby 4.0.6 + Rails 8.1.3 (API mode) |
| Arquitetura | Hexagonal (ports & adapters) |
| Web Server | Agoo (HTTP em C) + Thruster (TLS/HTTP2) |
| Banco | PostgreSQL 16+ |
| Cache/Filas | Redis 7+ + Sidekiq |
| Pagamentos | Asaas API v3 |
| Testes | RSpec + RuboCop |

## Termos Chave

- **Split:** divisão automática do valor de uma cobrança entre carteiras no
  Asaas, executada no momento do recebimento
- **Subconta:** conta Asaas vinculada à conta principal, com `walletId` próprio
- **`netValue`:** valor da cobrança após as taxas do Asaas. Todo split incide
  sobre ele
- **Estratégia de liquidação:** `:subaccount` ou `:pix_payout`, definida no
  cadastro da instituição e imutável
- **`SplitPolicy`:** tabela de faixas que define o percentual retido pela
  Clareo conforme o valor da doação

## Próximos Documentos

1. [Arquitetura](02-ARQUITETURA.md) — como o código está organizado
2. [Modelos de Dados](03-MODELOS-DADOS.md) — o schema
3. [Fluxos](04-FLUXOS.md) — como cada operação acontece
4. [Integração Asaas](16-INTEGRACAO-ASAAS.md) — o contrato com o provedor
5. [Custos e Receitas](11-CUSTOS-RECEITAS.md) — a matemática