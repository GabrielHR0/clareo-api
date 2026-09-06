# Clareo — Arquitetura do Sistema

## Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENTE                                  │
│                    (Browser/Mobile)                             │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                     FRONTEND                                    │
│                  (React/Next.js)                                │
└───────────────────────────────┬─────────────────────────────────┘
                                │ API REST (HTTPS + HTTP/2)
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                     KINO SERVER                                 │
│              (Rust Tokio/Hyper front-end)                       │
│              Ruby 4.0.6 + Ractor workers                        │
│              Mode: :threaded (Rails ainda não suporta Ractors)  │
├─────────────────────────────────────────────────────────────────┤
│                     RAILS API                                   │
│                  (Ruby 4.0.6 + Rails 8.1)                       │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐           │
│  │ Auth     │ │Donations │ │ Wallets  │ │Yield     │           │
│  │Controller│ │Controller│ │Controller│ │Controller│           │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘           │
│       │             │             │             │                 │
│       ▼             ▼             ▼             ▼                 │
│  ┌─────────────────────────────────────────────────────┐        │
│  │              SERVICE LAYER                          │        │
│  │  • BinanceService    • TronService                 │        │
│  │  • AaveService       • NowPaymentsService          │        │
│  │  • YieldService      • WithdrawalService           │        │
│  └─────────────────────────────────────────────────────┘        │
└───────────┬─────────────────────────────────────┬───────────────┘
            │                                     │
            ▼                                     ▼
┌───────────────────┐               ┌─────────────────────┐
│    PostgreSQL      │               │      Redis          │
│    (Banco de       │               │   (Cache/Filas)     │
│     Dados)         │               │                     │
└───────────────────┘               └─────────────────────┘
            │                                     │
            │                                     ▼
            │                           ┌─────────────────────┐
            │                           │     Sidekiq         │
            │                           │  (Jobs Assíncronos) │
            │                           └─────────────────────┘
            │                                     │
            │                                     ▼
            │                           ┌─────────────────────┐
            │                           │   Node.js Sidecar   │
            │                           │   (TronWeb API)     │
            │                           └─────────────────────┘
            │                                     │
            ▼                                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                    EXTERNOS                                      │
│  • Binance API    • TRON Network    • Aave V3                  │
│  • NOWPayments    • Solana          • Mercado Bitcoin           │
└─────────────────────────────────────────────────────────────────┘
```

## Decisões Técnicas

### Por que Kino e não Puma?

| Métrica | Kino | Puma |
|---------|------|------|
| Throughput | 229k req/s | 118k req/s |
| Memória (tiny app) | 148 MB | 1,068 MB |
| HTTP/2 | Nativo | Precisa nginx |
| Ractor support | Sim (quando Rails suportar) | Não |
| Rust I/O | Tokio/Hyper | Ruby puro |

**Benchmarks reais (AWS c7a.2xlarge, 8-core):**

| Endpoint | Kino :ractor | Kino :threaded | Puma cluster |
|----------|--------------|----------------|--------------|
| /plaintext | 229,534 | 216,994 | 118,176 |
| /10k | 178,083 | 160,400 | 106,768 |
| /cpu (fib) | 77,999 | 13,429 | 58,006 |
| /io (5ms) | 1,552 | 4,709 | 4,693 |

**Rails:** Kino roda em `:threaded` mode (Rails não suporta Ractors ainda), mas o Rust front-end já traz ganhos significativos.

### Por que TRON + Solana?

- **TRON:** 52% do volume de stablecoins, deep liquidity, universal support
- **Solana:** $0.0004 por transferência (2.500x mais barato que TRON)
- **Estratégia:** TRON para valores > $50, Solana para micro-transações

### Por que Binance + Mercado Bitcoin?

- **Binance:** 0.1% fee, melhor liquidez, API robusta
- **Mercado Bitcoin:** SPSAV autorizado, compliance garantido, fallback
- **Estratégia:** Binance como primário, MB como backup/compliance

### Por que Aave e não JustLend?

- **APY:** Aave 3-5% vs JustLend 1.35%
- **Risco:** Aave é o maior protocolo DeFi ($38.6B TVL)
- **Multi-chain:** Aave funciona em 15+ blockchains
- **Liquidez:** Saque a qualquer momento sem penalty

### Por que NOWPayments para PIX?

- **Widget pronto:** Não precisa desenvolver checkout
- **Non-custodial:** Fundos vão direto para nossa wallet
- **Taxa:** 0.5% (competitivo)
- **Suporte:** 350+ coins, auto-conversão

## Fluxo de Dados

1. **Doação:** Doador → NOWPayments → Binance → USDT → TRON/Solana → Aave
2. **Saque:** Beneficiário → Aave → Binance → PIX → Beneficiário
3. **Yield:** Sidekiq job (24h) → Aave API → Calcula rendimento → Atualiza saldo

## Cache e Performance

- Redis cache para preços de USDT (TTL: 30 segundos)
- Rate limiting: 20 requests/min por IP
- Connection pooling para PostgreSQL
