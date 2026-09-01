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
├─────────────────────────────────────────────────────────────────┤
│                     RAILS API                                   │
│                  (Ruby 4.0.6 + Rails 8.1.3)                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐           │
│  │ Auth     │ │Donations │ │ Wallets  │ │Yield     │           │
│  │Controller│ │Controller│ │Controller│ │Controller│           │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘           │
│       │             │             │             │                 │
│       ▼             ▼             ▼             ▼                 │
│  ┌─────────────────────────────────────────────────────┐        │
│  │              SERVICE LAYER                          │        │
│  │  • BinanceService    • TronService                 │        │
│  │  • JustLendService   • NowPaymentsService          │        │
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
│  • Binance API    • TRON Network    • JustLend                  │
│  • NOWPayments    • PIX             • JustLend                  │
└─────────────────────────────────────────────────────────────────┘
```

## Decisões Técnicas

### Por que Kino e não Puma?
- **Performance:** 1.5-1.7× mais throughput que Puma em I/O
- **HTTP/2 nativo:** +79% sobre HTTP/1.1, sem necessidade de nginx
- **Memória:** ~4× menos que Puma cluster em apps Rails
- **Ractor-ready:** Parallelismo real quando Rails suportar Ractors
- **Rust front-end:** Tokio/Hyper para I/O de alta performance
- **Config DSL familiar:** Mesmo estilo do Puma, fácil migração
- **Produção pronta:** Graceful drain, crash supervision, timeouts

### Por que TRON e não Ethereum?
- Gas fee ~$0.01 vs $5-50 no Ethereum
- Transações confirmadas em 3 segundos
- Suporte nativo a TRC-20 (USDT)
- Staking de TRX para transações gratuitas

### Por que JustLend e não Aave?
- Aave V3 ainda não está deployado no TRON
- JustLend é o maior protocolo de lending na TRON
- ~1.35% APY atual (conservador)
- Contratos auditados pela TronLink

### Por que Binance e não NOWPayments para tudo?
- Binance tem taxas menores para trading (0.1%)
- Melhor liquidez para USDT/BRL
- NOWPayments usado apenas para on-ramp via PIX

### Por que Sidecar Node.js?
- TronWeb é uma biblioteca JavaScript
- Tratar blockchain via API REST é mais complexo
- Sidecar mantém conexão persistente com TRON

## Fluxo de Dados

1. **Doação:** Cliente → Rails API → NOWPayments → Binance → USDT → TRON → JustLend
2. **Saque:** Beneficiário → Rails API → Binance → Vende USDT → PIX → Beneficiário
3. **Yield:** Sidekiq job (24h) → JustLend API → Calcula rendimento → Atualiza saldo

## Cache e Performance

- Redis cache para preços de USDT (TTL: 30 segundos)
- Rate limiting: 20 requests/min por IP
- Connection pooling para PostgreSQL
