# Clareo — Custos e Receitas

## Modelo de Negócio

Plataforma SaaS de doações com conversão automática para USDT e geração de yield.

## Fontes de Receita

| Fonte | Descrição | Margem |
|-------|-----------|--------|
| **Taxa de serviço** | 2% cobrado por doação | 45% |
| **Yield gerado** | Rendimento USDT (JustLend) | 100% |
| **Planos SaaS** | Básico/Pro/Enterprise | 80% |

## Custos Variáveis por Doação (R$100)

| Etapa | Custo | Observação |
|-------|-------|------------|
| PIX (comerciante) | R$0,50 | Taxa média mercado |
| Binance spread | R$0,20 | 0.2% da transação |
| TRON gas (staking) | R$0,05 | Com stake de TRX |
| JustLend deposit | R$0,05 | Gas fee |
| JustLend withdraw | R$0,05 | Gas fee |
| **Total variável** | **R$1,10** | **1.1% do valor** |

## Margem por Doação

| Item | Valor |
|------|-------|
| Receita (2% de R$100) | R$2,00 |
| Custo variável | R$1,10 |
| **Lucro por doação** | **R$0,90** |
| **Margem** | **45%** |

## Yield Estimado (4% APY)

| Volume Mensal | Yield Mensal | Yield Anual |
|---------------|--------------|-------------|
| R$10.000 | R$110 | R$1.320 |
| R$50.000 | R$550 | R$6.600 |
| R$100.000 | R$1.100 | R$13.200 |
| R$500.000 | R$5.500 | R$66.000 |
| R$1.000.000 | R$11.000 | R$132.000 |

## Projeção de Lucro (12 meses)

### Cenário Conservador (100 doações/mês, R$100 média)

| Mês | Doações | Receita Fee | Yield | Lucro Total |
|-----|---------|-------------|-------|-------------|
| 1 | 100 | R$200 | R$11 | R$101 |
| 2 | 150 | R$300 | R$22 | R$202 |
| 3 | 200 | R$400 | R$33 | R$303 |
| 6 | 350 | R$700 | R$66 | R$556 |
| 12 | 600 | R$1.200 | R$132 | R$992 |

### Cenário Otimista (500 doações/mês, R$200 média)

| Mês | Doações | Receita Fee | Yield | Lucro Total |
|-----|---------|-------------|-------|-------------|
| 1 | 500 | R$2.000 | R$110 | R$1.010 |
| 3 | 750 | R$3.000 | R$220 | R$1.870 |
| 6 | 1.000 | R$4.000 | R$440 | R$2.920 |
| 12 | 1.500 | R$6.000 | R$880 | R$4.620 |

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
| R$5.000 | ~2.778 doações |

## Custos Fixos Mensais

| Item | Custo |
|------|-------|
| VPS (2 vCPU, 4GB RAM) | R$50-100 |
| PostgreSQL (managed) | R$50-100 |
| Redis (managed) | R$20-50 |
| Domínio + SSL | R$10 |
| **Total** | **R$130-260** |

## Considerações Fiscais

- **IR sobre yield:** 15-22.5% (maior faixa)
- **Lucro da plataforma:** Tributado conforme regime escolhido
- **USDT:** Considerado moeda virtual pela Receita Federal
- **Necessário:** Contador especializado em criptoativos
