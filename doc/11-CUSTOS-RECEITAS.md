# Clareo — Custos e Receitas

## Modelo de Negócio

Plataforma SaaS de doações com conversão automática para USDT e geração de yield.

## Fontes de Receita

| Fonte | Descrição | Margem |
|-------|-----------|--------|
| **Taxa de serviço** | 2% cobrado por doação | Alta |
| **Yield gerado** | Rendimento USDT (Aave V3) | 100% |
| **Planos SaaS** | Básico/Pro/Enterprise | 80% |

## Custos Variáveis por Doação (R$100)

### Etapa 1 (Validar)

| Etapa | Custo | Observação |
|-------|-------|------------|
| NOWPayments (PIX) | R$0.50 | 0.5% da transação |
| Binance spread | R$0.10 | 0.1% da transação |
| TRON gas | R$1.44 | ~$0.14 em TRX |
| **Total variável** | **R$2.04** | **2.04% do valor** |

### Etapa 3 (Otimizado)

| Etapa | Custo | Observação |
|-------|-------|------------|
| NOWPayments (PIX) | R$0.50 | 0.5% da transação |
| Binance spread | R$0.10 | 0.1% da transação |
| TRON gas (energy rental) | R$0.40 | Com energy rental |
| **Total variável** | **R$1.00** | **1.00% do valor** |

## Margem por Doação

### Etapa 1

| Item | Valor |
|------|-------|
| Receita (2% de R$100) | R$2.00 |
| Custo variável | R$2.04 |
| **Lucro por doação** | **-R$0.04** |
| **Margem** | **-2%** |

### Etapa 3 (com yield)

| Item | Valor |
|------|-------|
| Receita (2% de R$100) | R$2.00 |
| Custo variável | R$1.00 |
| Yield (5% APY / 365) | R$0.01 |
| **Lucro por doação** | **R$1.01** |
| **Margem** | **50.5%** |

## Yield Estimado (4% APY - Aave V3)

| Volume Mensal | Yield Mensal | Yield Anual |
|---------------|--------------|-------------|
| R$10.000 | R$110 | R$1.320 |
| R$50.000 | R$550 | R$6.600 |
| R$100.000 | R$1.100 | R$13.200 |
| R$500.000 | R$5.500 | R$66.000 |
| R$1.000.000 | R$11.000 | R$132.000 |

## Planos SaaS

| Plano | Taxa | Doações/mês | Preço |
|-------|------|-------------|-------|
| Básico | 2.5% | 100 | Gratuito |
| Pro | 2.0% | 1.000 | R$97/mês |
| Enterprise | 1.5% | Ilimitado | R$497/mês |

## Break-Even

| Custo Fixo Mensal | Doações Necessárias (R$100 média) |
|-------------------|-----------------------------------|
| R$500 | ~278 doações |
| R$1.000 | ~556 doações |
| R$2.000 | ~1.112 doações |

## Custos Fixos Mensais

| Item | Custo |
|------|-------|
| VPS (2 vCPU, 4GB RAM) | R$50-100 |
| PostgreSQL (managed) | R$50-100 |
| Redis (managed) | R$20-50 |
| Domínio + SSL | R$10 |
| **Total** | **R$130-260** |

## Comparativo: Modelo Atual vs Otimizado

### Doação de R$100

| Modelo | Custo Total | % |
|--------|-------------|---|
| Modelo Atual (docs) | R$3.14 | 3.14% |
| Etapa 1 | R$2.04 | 2.04% |
| Etapa 3 | R$1.00 | 1.00% |

### Saque de R$100

| Modelo | Custo Total | % |
|--------|-------------|---|
| Modelo Atual (docs) | R$1.70 | 1.70% |
| Etapa 2+ | R$0.60 | 0.60% |

## Economia Anual (R$100k/mês volume)

| Modelo | Custo Anual | Economia |
|--------|-------------|----------|
| Modelo Atual | R$37.680 | - |
| Etapa 3 | R$12.000 | **R$25.680 (68%)** |
