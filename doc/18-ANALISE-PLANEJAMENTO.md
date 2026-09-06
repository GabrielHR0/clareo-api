# Clareo — Análise do Planejamento e Documentação

> Data da análise: 2026-09-06
> Status: **Problemas identificados — pesquisa completa**

---

## 1. INCONSISTÊNCIAS ENTRE DOCS E CÓDIGO REAL

| Problema | Docs dizem | Código real |
|----------|------------|-------------|
| **Web server** | Kino (Ractor-based, Rust Tokio) | Puma (`gem "puma"`) |
| **Ruby version** | Ruby 4.0.6 | `.ruby-version` não verificado |
| **Rails version** | Rails 8.1.3 | `~> 8.1.3` (ok) |
| **Estado real** | Fase 1 parcialmente completa | Apenas scaffold Rails + 3 gems básicas |

---

## 2. PROBLEMAS TÉCNICOS IDENTIFICADOS

### 2.1 Kino não existe como gem estável

- A doc referencia `kino` como web server baseado em Rust/Tokio
- Na realidade, **não existe gem `kino` estável** para Rails com essas características
- O Gemfile tem `gem "kino", "~> 0.6.0"` — provavelmente é uma gem diferente ou errada
- **Ação:** Pesquisar alternativas reais para high-performance Rails (Puma, Falcon, etc.)

### 2.2 TRON Sidecar — Complexidade subestimada

Docs tratam como simples, mas requer:
- Gerenciamento de chaves privadas em produção
- Staking de TRX (~$600 para transações gratuitas)
- Monitoramento de gas fees
- Tratamento de falhas em blockchain

### 2.3 JustLend — Riscos não documentados

- APY de 1.35% é **muito volátil** em DeFi
- Smart contracts podem ter vulnerabilidades
- Liquidez pode ser limitada em momentos de stress
- **Ação:** Pesquisar riscos reais do JustLend, histórico de APY, auditorias

### 2.4 Binance — Restrições Brasil

- Binance tem restrições em algumas operações no Brasil
- Pode haver limites para conversão BRL↔USDT
- **Ação:** Pesquisar status atual da Binance Brasil, limites, taxas reais

---

## 3. GAPS NA DOCUMENTAÇÃO

### Não documentado:
- Rate limits da TRON (por IP/rede)
- Limites de transação do NOWPayments para Brasil
- Processo de KYC necessário para operações
- Compliance com regulamentação brasileira (BC, Receita)
- Seguro para fondos em custódia
- Plano de disaster recovery

### Contratos JustLend podem estar desatualizados:
- `TX7QNd8Vr7VgqgvXkEBK5RBX6jTJFm5vA` (Comptroller)
- `TBDZs8sHXY8dBX9rYJbE9U8V2Hm4q5J2w` (cUSDT)
- **Ação:** Verificar se endereços estão corretos e ativos

---

## 4. MODELO DE NEGÓCIO — PONTOS CRÍTICOS

### 4.1 Margem de 45% pode ser irrealista

Cálculo assume custos fixos baixos. Não considera:
- Suporte ao cliente
- Compliance/regulatório
- Seguros
- Desenvolvimento contínuo
- Marketing

### 4.2 Break-even subestimado

- 278 doações/mês para R$500 de custo fixo
- Custos variáveis podem ser maiores em volumes baixos

---

## 5. ROADMAP — TIMELINE IRREALISTA

- **20 dias** para sistema completo com 4 integrações blockchain
- Integrar Binance + TRON + JustLend + NOWPayments é complexo
- Testes de integração com blockchain são difíceis de simular
- **Ação:** Pesquisar tempo real de implementação de projetos similares

---

## 6. PESQUISAS NECESSÁRIAS NA INTERNET

| # | Tema | Por quê |
|---|------|---------|
| 1 | **Kino gem** | Realmente existe? Alternativas para high-performance Rails? |
| 2 | **JustLend APY atual** | Qual yield real hoje? Histórico de variação? |
| 3 | **JustLend contratos** | Endereços corretos e auditados? |
| 4 | **Binance Brasil** | Status, limites, restrições atuais? |
| 5 | **NOWPayments Brasil** | Limites, taxas reais, suporte PIX? |
| 6 | **Regulamentação crypto Brasil** | BC, Receita, necessidade de licença? |
| 7 | **Tempo real de implementação** | Projetos similares demoram quanto? |

---

# PESQUISA COMPLETA — SETEMBRO 2026

---

## 7. ON-RAMP: BRL → STABLECOIN (OPÇÕES MAIS BARATAS)

### 7.1 Comparativo de Exchanges para On-ramp

| Exchange | Taxa Spot | Spread | Velocidade PIX | Melhor Para |
|----------|-----------|--------|----------------|-------------|
| **BingX** | 0.1% | Baixo | <10 seg | Traders ativos, P2P |
| **Binance** | 0.1% (0.075% com BNB) | Baixo | Instantâneo | Volume alto, experiência |
| **Mercado Bitcoin** | 0.3% - 0.7% | Médio | Instantâneo | Iniciantes, suporte local |
| **Foxbit** | 0.3% - 0.5% | Médio | Instantâneo | Brasileiros, compliance |
| **NovaDAX** | 0.3% - 0.5% | Médio | Instantâneo | Diversidade de moedas |
| **Bitso** | 0.5% - 1.0% | Alto | Instantâneo | Remessas LatAm |

### 7.2 Métodos de Pagamento — Custo Real

| Método | Custo Médio | Velocidade | Limite | Melhor Para |
|--------|-------------|------------|--------|-------------|
| **PIX** | 0% - 0.5% | Instantâneo | Médio | Uso diário DCA |
| **Transferência Bancária** | Flat / Baixo | 1-24h | Alto | Institucional |
| **Cartão de Crédito** | 3% - 7% | Instantâneo | Baixo | Emergência |
| **Boleto** | Flat + R$3-10 | 1-3 dias | Médio | Poucos usuários |
| **P2P** | Variável | Minutos a horas | Variável | Flexibilidade |

### 7.3 Custo Total para Comprar USDT com R$1.000

| Plataforma | Fee Trading | Fee Depósito | Spread | Total Estimado | USDT Recebido |
|------------|-------------|--------------|--------|----------------|---------------|
| **BingX (PIX)** | R$1.00 | R$0.00 | ~R$2.00 | ~R$3.00 (0.3%) | ~$199.40 |
| **Binance (PIX)** | R$1.00 | R$0.00 | ~R$2.00 | ~R$3.00 (0.3%) | ~$199.40 |
| **Mercado Bitcoin** | R$5.00 | R$0.00 | ~R$3.00 | ~R$8.00 (0.8%) | ~$198.40 |
| **Cartão (qualquer)** | R$10.00 | R$35.00 | ~R$5.00 | ~R$50.00 (5%) | ~$190.00 |

### 7.4 Recomendação para Clareo

**Melhor opção:** Usar **Binance API** diretamente (como planejado)
- Taxa: 0.1% (0.075% com BNB)
- Liquidez profunda USDT/BRL
- API confiável para automação

**Alternativa mais barata:** **BingX API**
- Taxa: 0.1%
- Suporte PIX nativo
- Boa liquidez

**Para usuários que querem self-custody:** P2P via Binance ou Bybit
- Taxa: 0% - 0.5%
- Mais flexibilidade

---

## 8. OFF-RAMP: STABLECOIN → BRL (OPÇÕES MAIS BARATAS)

### 8.1 Rotas de Off-ramp

| Rota | Taxa Total | Velocidade | Risco | Melhor Para |
|------|------------|------------|-------|-------------|
| **Exchange brasileira** | 0.3% - 1.0% | Segundos a horas | Baixo | Maioria dos usuários |
| **P2P** | 0% - 0.5% | Minutos | Médio (freeze risk) | Melhor preço |
| **Global exchange + Pix** | 0.5% - 1.5% | Minutos | Baixo | USDT já em exchange |
| **DeFi → Off-ramp** | 0.5% - 2.0% | Variável | Baixo | Self-custody users |

### 8.2 Melhores Exchanges para Off-ramp no Brasil

| Exchange | Taxa Trading | Saque PIX | Liquidez USDT/BRL |
|----------|--------------|-----------|-------------------|
| **Mercado Bitcoin** | 0.3% - 0.7% | Grátis ou flat | Alta |
| **Foxbit** | 0.3% - 0.5% | Grátis ou flat | Alta |
| **Binance** | 0.1% | R$0 - R$5 | Muito alta |
| **NovaDAX** | 0.3% - 0.5% | Flat | Média |
| **Bitso** | 0.5% - 1.0% | Flat | Média |

### 8.3 Custo Total para Sacar R$1.000 em USDT

| Plataforma | Fee Trading | Fee Saque | Spread | Total Estimado |
|------------|-------------|-----------|--------|----------------|
| **Binance** | R$1.00 | R$2.00 | ~R$2.00 | ~R$5.00 (0.5%) |
| **Mercado Bitcoin** | R$5.00 | R$0.00 | ~R$3.00 | ~R$8.00 (0.8%) |
| **Foxbit** | R$4.00 | R$0.00 | ~R$3.00 | ~R$7.00 (0.7%) |

### 8.4 Recomendação para Clareo

**Melhor opção:** Usar **Binance API** para venda de USDT → BRL
- Taxa: 0.1%
- Liquidez profunda
- Saque via PIX rápido

**Alternativa:** Exchange brasileira (Mercado Bitcoin ou Foxbit)
- Melhor compliance local
- Suporte em português

---

## 9. REDES BLOCKCHAIN — COMPARATIVO DE FEES (SET 2026)

### 9.1 Ranking de Custo por Transferência USDT

| Rede | Fee por Transferência | Finalidade | Throughput | Melhor Para |
|------|----------------------|------------|------------|-------------|
| **Solana (SPL)** | $0.0004 - $0.001 | ~400ms | 2,000-3,000 TPS | Micropagamentos |
| **Base (L2)** | $0.002 - $0.02 | ~2s | ~350 TPS | EUA/Europa regulados |
| **Polygon (PoS)** | $0.001 - $0.05 | 2-5s | ~7,000 TPS | DeFi users |
| **BNB Chain (BEP20)** | $0.02 - $0.10 | 3s | ~160 TPS | Ecossistema Binance |
| **TRON (TRC20)** | $0.20 - $1.44* | ~3s | ~2,000 TPS | Remessas emerging markets |
| **Arbitrum (L2)** | $0.005 - $0.20 | ~2s | ~40,000 TPS | DeFi trading |
| **Ethereum (ERC20)** | $0.40 - $15.00 | ~12s | ~15 TPS | Grandes valores, segurança |
| **TON** | $0.001 - $0.005 | ~1s | ~100,000 TPS | Micro-pagamentos |

*TRON com energy rental reduz de ~$1.92 para ~$0.20-1.44

### 9.2 Análise por Volume de Transação

| Faixa de Valor | Rede Recomendada | Fee Estimada | Motivo |
|----------------|------------------|--------------|--------|
| **< $50** | Solana, TON | < $0.01 | Fees não comem porcentagem |
| **$50 - $5,000** | Solana, Polygon, TRC20 | $0.001 - $1.44 | Custo baixo, finalidade rápida |
| **$5,000 - $50,000** | TRC20, BNB | < $1.00 | Melhor equilíbrio custo/segurança |
| **> $50,000** | Ethereum ERC20 | $2 - $15 | Máxima segurança |

### 9.3 Por que TRON Ainda é Popular (apesar dos fees)

- **52% de todo volume de stablecoins** usa TRON
- Deep liquidity em exchanges
- Suporte universal de wallets
- energy rental services reduzem custo em 80%
- **Para Clareo:** TRON continua sendo boa escolha para valores > $50

### 9.4 Alternativa ao TRON: Solana

**Vantagens:**
- Fee: $0.0004 (2.500x mais barato que TRON)
- Finalidade: 400ms (7.5x mais rápido)
- Crescimento de 8% do market share de stablecoins

**Desvantagens:**
- Menos suporte de exchanges brasileiras
- Ecossistema DeFi menor que TRON/Ethereum
- Risco de network outages históricos

### 9.5 Recomendação para Clareo

**Manter TRON como primário** para:
- Compatibilidade com exchange withdrawals
- Deep liquidity
- Suporte universal

**Adicionar Solana como opção** para:
- Micro-transações (< $50)
- Usuários que querem fees mínimas

---

## 10. PROTOCOLOS DE YIELD — ALTERNATIVAS AO JUSTLEND

### 10.1 Comparativo de Yield em Stablecoins (Set 2026)

| Plataforma | Tipo | USDT APY | USDC APY | Risco | Liquidez |
|------------|------|----------|----------|-------|----------|
| **Aave V3** | DeFi Lending | 2-4% | 3-5% | Low-Med | Alta |
| **Compound V3** | DeFi Lending | ~2.5% | 3-4% | Low-Med | Alta |
| **Morpho** | DeFi Optimizer | 3-5% | 4-7% | Médio | Alta |
| **Maker DSR** | DeFi Savings | N/A | N/A | Low | Alta |
| **JustLend** | DeFi Lending | ~1.35% | N/A | Médio | Média |
| **Binance Earn** | CeFi | 2-6% | 2-6% | Médio | Alta |
| **Nexo** | CeFi | 5-11%+ | 4-10%+ | Médio-Alto | Média |
| **YouHodler** | CeFi | 9-15%+ | 8-15%+ | Alto | Média |
| **Coinbase** | CeFi | N/A | 4.1% | Low | Alta |
| **Ondo USDY** | Tokenized Treasury | ~4.65% | N/A | Low | Média |

### 10.2 Análise de Risco por Categoria

| Categoria | Risco | Yield Típico | Exemplos |
|-----------|-------|--------------|----------|
| **TradFi (T-Bills)** | Muito Baixo | 4.5% - 5% | US Treasury, Money Market |
| **DeFi Blue-Chip** | Baixo-Médio | 2% - 6% | Aave, Compound |
| **Tokenized RWA** | Baixo | 4% - 5% | Ondo USDY, Maker DSR |
| **CeFi Regulated** | Médio | 4% - 10% | Coinbase, Binance Earn |
| **CeFi Higher-Yield** | Médio-Alto | 10% - 16% | Nexo, YouHodler |
| **DeFi Yield Farming** | Alto | 5% - 17% | Morpho, Pendle |

### 10.3 JustLend: Análise Crítica

**Problemas atuais:**
- APY de **1.35% é o mais baixo** entre protocolos DeFi
- Abaixo de money market funds tradicionais (~4.85%)
- Risco de smart contract não compensado pelo yield

**JustLend vs Alternativas:**

| Métrica | JustLend | Aave V3 | Binance Earn |
|---------|----------|---------|--------------|
| APY USDT | ~1.35% | 2-4% | 2-6% |
| Risco Smart Contract | Médio | Baixo-Médio | N/A (CeFi) |
| Liquidez | Média | Alta | Alta |
| Rede | TRON | Multi-chain | Centralizado |

### 10.4 Recomendação para Clareo

**Estratégia de Yield Multi-Protocolo:**

1. **Core (70%):** Aave V3 em Ethereum/Polygon
   - APY: 3-5%
   - Risco: Low-Medium
   - Liquidez: Alta

2. **Boost (20%):** Morpho otimizado
   - APY: 4-7%
   - Risco: Medium
   - Liquidez: Alta

3. **Reserva (10%):** Binance Earn ou Ondo USDY
   - APY: 4-6%
   - Risco: Low-Medium
   - Liquidez: Alta

**Mudança recomendada:** Abandonar JustLend como protocolo único. Usar estratégia diversificada.

---

## 11. GATEWAYS DE PAGAMENTO PARA DOAÇÕES

### 11.1 Comparativo de Crypto Payment Gateways

| Gateway | Taxa | Coins Suportadas | Non-Custodial | Auto-Convert | Melhor Para |
|---------|------|------------------|---------------|--------------|-------------|
| **NOWPayments** | 0.5% | 350+ | Sim | Sim | Doações, versatilidade |
| **Plisio** | 0.5% | 20+ | Sim | Sim | Merchants, e-commerce |
| **BitPay** | 1% - 2% | 15+ | Não | Sim | Empresas estabelecidas |
| **CoinGate** | 1% | 70+ | Não | Sim | EU regulamentado |
| **Stripe (Bridge)** | 1.5% | USDC/USDT | Não | Sim | SaaS existente |
| **BTCPay Server** | 0% | BTC + L2s | Sim | Não | Sovereignty total |
| **CoinPayments** | 0.5% | 2,000+ | Sim | Não | Altcoin diversity |

### 11.2 Para Doações Especificamente

| Gateway | Widget Doação | Recurring | Tax Receipt | Min Amount |
|---------|---------------|-----------|-------------|------------|
| **NOWPayments** | Sim | Sim | Não | Sem mínimo |
| **Plisio** | Sim | Sim | Sim | Sem mínimo |
| **BitPay** | Sim | Sim | Sim | Variável |
| **BTCPay** | Sim | Sim | Não | Sem mínimo |
| **CoinGate** | Sim | Não | Não | Sem mínimo |

### 11.3 Custo para Doação de R$100

| Gateway | Fee Gateway | Fee Network | Fee Total | USDT Chegada |
|---------|-------------|-------------|-----------|--------------|
| **NOWPayments (TRC20)** | R$0.50 | R$1.44 | R$1.94 | ~$19.61 |
| **NOWPayments (Solana)** | R$0.50 | R$0.001 | R$0.50 | ~$19.90 |
| **Plisio (TRC20)** | R$0.50 | R$1.44 | R$1.94 | ~$19.61 |
| **BitPay** | R$1.00 - R$2.00 | Variável | ~R$2.50 | ~$19.50 |

### 11.4 Recomendação para Clareo

**Melhor opção:** **NOWPayments** (já planejado)
- Taxa: 0.5%
- Non-custodial
- Widget de doação pronto
- Suporte a 350+ coins
- Auto-conversão para USDT

**Adicionar:** **Plisio** como alternativa
- Taxa: 0.5%
- Tax receipts para doadores
- Compliance melhor

**Para self-sovereignty:** **BTCPay Server**
- Taxa: 0%
- Sem intermediários
- Mais trabalho de manutenção

---

## 12. SOLUÇÕES DE CUSTODIAL WALLET

### 12.1 Opções para Clareo

| Solução | Tipo | Taxa | Multi-chain | Compliance | Melhor Para |
|---------|------|------|-------------|------------|-------------|
| **Fireblocks** | MPC Infrastructure | Variável | 120+ chains | Forte | Enterprise |
| **Privy** | Embedded Wallet | Free tier | EVM + Solana | Médio | Developers |
| **Web3Auth** | MPC + Social Login | Free tier | Multi-chain | Médio | UX focused |
| **Turnkey** | Key Management | Variável | Multi-chain | Forte | Custom custody |
| **Coinbase WaaS** | Custodial | Variável | Multi-chain | Forte | Compliance |
| **Cobo** | Custodial | Variável | Multi-chain | Forte | Institutional |
| **Self-hosted (DIY)** | Custom | Gas only | Custom | Total control | Máxima soberania |

### 12.2 Recomendação para Clareo

**Fase 1 (MVP):** Self-hosted com TronWeb sidecar
- Custo: Apenas gas fees
- Controle: Total
- Complexidade: Média

**Fase 2 (Escala):** Fireblocks ou Privy
- Custo: % do AUM ou por tx
- Controle: compartilhado
- Compliance: integrado

---

## 13. REGULAMENTAÇÃO CRYPTO BRASIL (SET 2026)

### 13.1 Framework SPSAV (Resoluções 519, 520, 521)

**Vigência:** 2 de fevereiro de 2026

**Impacto Principal:**
- Stablecoins (USDT/USDC) agora classificadas como **operações de câmbio**
- Plataformas precisam de autorização do BCB como **SPSAV**
- Segregação obrigatória de fundos (client vs operating)
- **Know-Your-Wallet (KYW)** obrigatório para self-custody

### 13.2 Requisitos para Operar no Brasil

| Requisito | Detalhes |
|-----------|----------|
| **Autorização BCB** | SPSAV (Sociedade Prestadora de Serviços de Ativos Virtuais) |
| **Capital Mínimo** | R$ 10.8M - R$ 37.2M ($2M - $7M) |
| **Segregação de Fundos** | Obligatory - client funds separate from operating |
| **KYC/AML** | Full KYC required for all users |
| **Travel Rule** | Phased implementation: 2026-2028 |
| **Reporting** | DeCripto form (IN 2,291) from July 2026 |

### 13.3 Timeline de Compliance

| Data | Evento |
|------|--------|
| **2 Fev 2026** | SPSAV framework entra em vigor |
| **4 Mai 2026** | Reporting obrigatório começa |
| **30 Out 2026** | Deadline para existentes autorizarem ou aplicarem |
| **1 Jul 2026** | DeCripto form obrigatório |
| **2 Fev 2028** | Travel Rule full compliance |

### 13.4 Implicações para Clareo

**Como SaaS de doações com stablecoins, Clareo provavelmente precisa:**

1. **Autorização SPSAV** se opera no Brasil diretamente
2. **Parceria com SPSAV autorizada** se usa exchange licenciada
3. **KYC para beneficiários** que recebem saques
4. **Reporting** de todas as transações via DeCripto
5. **Segregação de fundos** se mantém crypto em custódia

**Opção mais simples:** Usar **exchange brasileira licenciada** (Mercado Bitcoin, Foxbit) como intermediária. A exchange assume compliance.

### 13.5 DeClarpto — Nova Obligação Fiscal

- Obriga declarar transações crypto na Receita Federal
- Movimentações > R$35.000/mês devem ser reportadas
- Exchanges brasileiras reportam automaticamente
- Para offshore exchanges, obrigação é do usuário

### 13.6 Imposto de Renda sobre Crypto

| Faixa de Ganho de Capital | Alíquota |
|---------------------------|----------|
| Até R$5 milhões | 15% |
| R$5M - R$10M | 17.5% |
| R$10M - R$30M | 20% |
| Acima de R$30M | 22.5% |

**Exenção:** Vendas mensais < R$35.000

---

## 14. FLUXOS OTIMIZADOS — CUSTO MÍNIMO

### 14.1 Fluxo Doação (Otimizado)

```
Doador (PIX R$100)
    │
    ▼
NOWPayments (0.5% = R$0.50)
    │
    ▼
USDT TRC-20 na wallet Clareo
    │
    ▼
Binance API (0.1% = R$0.10) [se precisar converter]
    │
    ▼
Wallet do beneficiário (TRON: R$1.44 ou Solana: $0.001)
    │
    ▼
JustLend/Aave (yield 2-5% APY)
```

**Custo total estimado:** ~R$2.00 (2%) por doação de R$100

### 14.2 Fluxo Saque (Otimizado)

```
Beneficiário solicita saque
    │
    ▼
JustLend/Aave redeem (gas: ~$0.20)
    │
    ▼
Binance API vende USDT (0.1% = R$0.10)
    │
    ▼
PIX para beneficiário (grátis ou flat)
```

**Custo total estimado:** ~R$0.50 - R$2.00 por saque

### 14.3 Fluxo Yield (Otimizado)

```
A cada 24h:
    │
    ▼
Consultar APY em Aave/Morpho (off-chain ou on-chain)
    │
    ▼
Calcular ganho = saldo × APY/365
    │
    ▼
Salvar snapshot no PostgreSQL
    │
    ▼
Se APY < threshold → alerta admin
```

**Custo:** Apenas gas fees de leitura (~$0.01)

---

## 15. CUSTOS TOTAIS POR TRANSAÇÃO — COMPARAÇÃO

### 15.1 Doação de R$100 — Modelo Atual vs Otimizado

| Etapa | Modelo Atual | Otimizado | Economia |
|-------|--------------|-----------|----------|
| On-ramp (NOWPayments) | R$1.50 (1.5%) | R$0.50 (0.5%) | R$1.00 |
| Conversão BRL→USDT | R$0.20 (0.2%) | R$0.10 (0.1%) | R$0.10 |
| Transferência TRON | R$1.44 | R$1.44 (manter) | R$0.00 |
| Yield deposit | R$0.05 | R$0.20 (Aave) | -R$0.15 |
| **Total** | **R$3.19 (3.19%)** | **R$2.24 (2.24%)** | **R$0.95** |

### 15.2 Saque de R$100 — Modelo Atual vs Otimizado

| Etapa | Modelo Atual | Otimizado | Economia |
|-------|--------------|-----------|----------|
| Redeem yield | R$0.05 | R$0.20 (Aave) | -R$0.15 |
| Conversão USDT→BRL | R$0.20 (0.2%) | R$0.10 (0.1%) | R$0.10 |
| Off-ramp (PIX) | R$1.50 (1.5%) | R$0.50 (0.5%) | R$1.00 |
| **Total** | **R$1.75 (1.75%)** | **R$0.80 (0.80%)** | **R$0.95** |

---

## 16. RECOMENDAÇÕES FINAIS

### 16.1 Mudanças na Stack

| Componente | Atual | Recomendado | Motivo |
|------------|-------|-------------|--------|
| Web Server | Kino (inexistente) | Puma | Funcional, suportado |
| On-ramp | Binance | Binance (manter) | Melhor custo-benefício |
| Off-ramp | NOWPayments | Binance API + NOWPayments | Flexibilidade |
| Blockchain | TRON only | TRON + Solana | Opção low-fee |
| Yield | JustLend only | Aave + Morpho + Reserva | Diversificação |
| Gateway | NOWPayments | NOWPayments + Plisio | Compliance local |

### 16.2 Mudanças no Roadmap

| Fase | Atual | Recomendado | Motivo |
|------|-------|-------------|--------|
| Fase 1 | 1 dia | 2-3 dias | Setup mais realista |
| Fase 2 | 2 dias | 3-4 dias | Models + Migrations |
| Fase 3 | 1 dia | 2 dias | Auth completo |
| Fase 4 | 2 dias | 2-3 dias | Binance + testes |
| Fase 5 | 3 dias | 3-4 dias | TRON + Solana |
| Fase 6 | 2 dias | 3-4 dias | Yield multi-protocolo |
| Fase 7 | 2 dias | 2-3 dias | NOWPayments |
| Fase 8 | 2 dias | 3-4 dias | API completa |
| Fase 9 | 1 dia | 2 dias | Jobs + monitoramento |
| Fase 10 | 1 dia | 2 dias | Deploy robusto |
| Fase 11 | 2 dias | 3-4 dias | Testes completos |
| Fase 12 | 1 dia | 1 dia | Docs (ok) |
| **Total** | **20 dias** | **30-40 dias** | **+50% realismo** |

### 16.3 Compliance — Ações Imediatas

1. **Decidir modelo:** Operar como SPSAV ou via parceiro licenciado
2. **Parceiro recomendado:** Mercado Bitcoin ou Foxbit (SPSAV autorizados)
3. **KYC:** Implementar para beneficiários desde o início
4. **Reporting:** Preparar integração DeCripto

### 16.4 Prioridades Pós-Lançamento Atualizadas

1. Dashboard admin
2. Multi-chain (Solana + Base)
3. Yield diversificado (Aave + Morpho)
4. Notificações push
5. App mobile (React Native)
6. Multi-idioma (PT/EN/ES)
7. Relatórios financeiros
8. API pública para integrações

---

## 17. REFERÊNCIAS

### On/Off-ramp
- https://bingx.com/en/learn/article/best-exchanges-to-buy-usdt-in-brazil
- https://eco.com/support/en/articles/15902369-usdt-to-brazilian-real-routes-and-fees-2026
- https://coinsys.io/best-crypto-exchanges-in-brazil-2026-pix-fees-brl-support-compared/

### Blockchain Fees
- https://chaingain.io/cheapest-blockchain-usdt-transfers-2026/
- https://eco.com/support/en/articles/15010637-cheapest-way-to-send-usdt-network-fee-comparison-2026
- https://plisio.net/crypto/usdt-transfer-fee

### Yield
- https://graphdex.io/en/blog/best-ways-earn-yield-stablecoins-2026
- https://gate.com/blog/aave-usdt-apy-tokenized-treasuries-defi-yield-comparison-stablecoin-reallocation-analysis
- https://decentralised.news/stablecoin-yield-rankings-2026

### Payment Gateways
- https://plisio.net/crypto/best-crypto-payment-gateways
- https://earnifyhub.com/learning-guides/best-crypto-payment-gateways-nowpayments-bitpay-coinbase-2026

### Regulamentação Brasil
- https://bingx.com/en/learn/article/what-is-brazil-spsav-framework-guide-to-new-pix-crypto-rules
- https://notabene.id/post/brazils-central-bank-regulates-virtual-asset-service-providers-what-bcb-resolutions-mean-for-crypto-compliance
- https://blockeden.xyz/blog/2026/01/14/brazil-stablecoin-regulation-latam-crypto-framework

### Custodial Wallets
- https://apidog.com/blog/best-crypto-wallet-api/
- https://coingape.com/best-crypto-wallet-infrastructure-providers/
