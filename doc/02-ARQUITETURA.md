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
│  │ Auth     │ │Donations │ │ Wallets  │ │Withdrawals│           │
│  │Controller│ │Controller│ │Controller│ │Controller│           │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘           │
│       │             │             │             │                 │
│       ▼             ▼             ▼             ▼                 │
│  ┌─────────────────────────────────────────────────────┐        │
│  │              SERVICE LAYER                          │        │
│  │  • ExchangeInterface  • BlockchainInterface        │        │
│  │  • PaymentInterface   • DonationService            │        │
│  │  • WithdrawalService  • AuthService                │        │
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
│  • Binance API    • TRON Network    • NOWPayments              │
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

### Por que TRON?

- **Liquidez:** 52% do volume de stablecoins
- **Universal:** Aceito em todas as exchanges e wallets
- **Custo:** ~$0.14 por transferência TRC-20
- **Simples:** Uma blockchain, um padrão

### Por que Binance?

- **Taxa:** 0.1% (0.075% com BNB)
- **Liquidez:** Maior exchange do mundo
- **API:** Robusta e bem documentada
- **Par USDTBRL:** Disponível para compra/venda direta

### Por que NOWPayments para PIX?

- **Widget pronto:** Não precisa desenvolver checkout
- **Non-custodial:** Fundos vão direto para nossa wallet
- **Taxa:** 0.5% (competitivo)
- **Suporte:** 350+ coins, auto-conversão

## Fluxo de Dados

1. **Doação:** Doador → NOWPayments → Binance → USDT → TRON → Wallet
2. **Saque:** Instituição → Binance → USDT → BRL → PIX → Instituição

## Cache e Performance

- Redis cache para preços de USDT (TTL: 30 segundos)
- Rate limiting: 20 requests/min por IP
- Connection pooling para PostgreSQL
