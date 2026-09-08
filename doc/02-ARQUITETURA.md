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
│                     RAILS API                                   │
│                  (Ruby + Rails)                                  │
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
            ▼                                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                    EXTERNOS                                      │
│  • Exchange (compra/venda USDT)                                │
│  • Blockchain (wallets, transferências)                        │
│  • Gateway de pagamento (PIX)                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Decisões Técnicas

### Arquitetura: Strategy Pattern

Cada integração externa vira uma **classe que implementa a mesma interface**:

```
app/services/
├── exchange_interface.rb
├── blockchain_interface.rb
├── payment_interface.rb
├── exchanges/
│   └── binance_service.rb
├── blockchains/
│   └── tron_service.rb
└── payments/
    └── nowpayments_service.rb
```

### Por que Strategy?

- **Trocar provider:** criar nova classe, mudar env var
- **Testar:** mockar interface sem depender da API real
- **Novo provider:** só implementar a interface

## Fluxo de Dados

1. **Doação:** Doador → Gateway de pagamento → Exchange → Blockchain → Wallet
2. **Saque:** Instituição → Exchange → Gateway de pagamento → PIX → Instituição

## Cache e Performance

- Redis cache para preços de USDT (TTL: 30 segundos)
- Rate limiting: 20 requests/min por IP
- Connection pooling para PostgreSQL
