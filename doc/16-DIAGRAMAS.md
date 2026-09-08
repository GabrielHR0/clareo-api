# Clareo — Diagramas de Fluxo (MVP)

## 1. Visão Geral do Sistema

```mermaid
graph TB
    subgraph "Cliente"
        A[Browser/Mobile]
    end

    subgraph "Clareo API (Rails 8.1 + Kino)"
        B[API Controller]
        C[Service Layer]
    end

    subgraph "Dados"
        D[(PostgreSQL)]
        E[(Redis)]
    end

    subgraph "Jobs"
        F[Sidekiq]
    end

    subgraph "Externos"
        G[NOWPayments]
        H[Binance]
        I[TRON Network]
    end

    A -->|HTTPS| B
    B --> C
    C --> D
    C --> E
    C --> F
    F --> C
    C --> G
    C --> H
    C --> I
```

---

## 2. APIs Externas — O que cada uma faz

```mermaid
graph LR
    subgraph "NOWPayments (PIX Widget)"
        N1[BRL via PIX] -->|On-ramp| N2[USDT TRC-20]
        N3[BRL via PIX] -->|Off-ramp| N4[USDT TRC-20]
    end

    subgraph "Binance (Exchange)"
        B1[BRL] -->|Compra 0.1%| B2[USDT]
        B2 -->|Vende 0.1%| B3[BRL]
        B4[Cotação USDT/BRL] -.->|Consulta| B5[GET /api/v3/ticker/price]
    end

    subgraph "TRON (Blockchain)"
        T1[Carteira] -->|Envia ~$1.44| T2[USDT TRC-20]
        T2 -->|Recebe| T3[Carteira]
    end
```

---

## 3. Fluxo de Doação (Passo a passo)

```mermaid
sequenceDiagram
    participant D as Doador
    participant A as Clareo API
    participant N as NOWPayments
    participant B as Binance
    participant T as TRON Network

    D->>A: POST /donations (valor R$)
    A->>A: Valida dados
    A->>N: Cria pagamento (0.5%)
    N-->>A: payment_url + payment_id
    A-->>D: Retorna URL de pagamento

    D->>N: Paga via PIX
    N->>N: Processa pagamento

    N->>A: Webhook: payment_status=finished
    A->>A: Verifica assinatura IPN

    A->>B: Compra USDT (0.1%)
    B-->>A: orderId + USDT comprado

    A->>T: Envia USDT TRC-20 (~$1.44)
    T-->>A: txHash

    A->>A: Atualiza saldo

    A-->>D: Confirmação (email/webhook)
```

### Status da Doação

```
pending → confirmed → failed
   │          │
   │          └── USDT convertido e depositado na wallet
   └── Pagamento criado no NOWPayments
```

---

## 4. Fluxo de Saque (Passo a passo)

```mermaid
sequenceDiagram
    participant I as Instituição
    participant A as Clareo API
    participant X as Binance
    participant N as NOWPayments
    participant T as TRON Network

    I->>A: POST /withdrawals (valor R$)
    A->>A: Valida dados + calcula USDT necessário

    A->>T: Consulta saldo da wallet
    T-->>A: saldo USDT

    alt Saldo suficiente
        A->>X: Vende USDT para BRL (0.1%)
        X-->>A: BRL na conta Binance

        A->>T: Transfere USDT (se necessário)
        T-->>A: txHash

        A->>N: Envia PIX (0.5%)
        N-->>A: withdrawal_id

        N->>I: PIX enviado
        A-->>I: Confirmação
    else Saldo insuficiente
        A-->>I: Erro: saldo insuficiente
    end
```

### Status do Saque

```
pending → processing → completed → failed
   │          │           │
   │          │           └── PIX enviado
   │          └── Convertendo USDT → BRL
   └── Solicitação criada
```

---

## 5. Fluxo de Autenticação

```mermaid
sequenceDiagram
    participant C as Cliente
    participant A as Clareo API
    participant DB as PostgreSQL
    participant R as Redis

    C->>A: POST /auth/login (email, password)
    A->>DB: SELECT * FROM users WHERE email = ?
    DB-->>A: user

    A->>A: bcrypt.verify(password, user.password_digest)
    A->>A: JWT.encode(user_id, secret, 24h)
    A-->>C: { token: "eyJ..." }

    loop Cada request autenticado
        C->>A: GET /api/v1/wallets + Authorization: Bearer eyJ...
        A->>A: JWT.decode(token)
        A->>A: Continua processamento
        A-->>C: Resposta
    end
```

---

## 6. Resumo das Integrações

| API | O que faz | Quando usa | Custo |
|-----|-----------|------------|-------|
| **NOWPayments** | On-ramp (PIX→USDT) + Off-ramp (USDT→PIX) | Doação + Saque | 0.5% |
| **Binance** | Compra/venda USDT | Doação + Saque | 0.1% |
| **TRON** | Blockchain, carteiras, transferências | Doação + Saque | ~$1.44 |

---

## 7. Architecture: Strategy Pattern

```mermaid
classDiagram
    class ExchangeInterface {
        <<interface>>
        +buy_usdt(amount_brl)
        +sell_usdt(amount_usdt)
        +get_price()
        +get_balance(asset)
    }

    class BlockchainInterface {
        <<interface>>
        +create_wallet()
        +get_balance(address)
        +transfer_usdt(from_key, to_address, amount)
    }

    class PaymentInterface {
        <<interface>>
        +create_payment(amount_brl, order_id)
        +send_pix(amount_brl, pix_key)
        +verify_ipn_signature(signature, body)
    }

    class BinanceService {
        +buy_usdt(amount_brl)
        +sell_usdt(amount_usdt)
        +get_price()
        +get_balance(asset)
    }

    class TronService {
        +create_wallet()
        +get_balance(address)
        +transfer_usdt(from_key, to_address, amount)
    }

    class NowPaymentsService {
        +create_payment(amount_brl, order_id)
        +send_pix(amount_brl, pix_key)
        +verify_ipn_signature(signature, body)
    }

    ExchangeInterface <|.. BinanceService
    BlockchainInterface <|.. TronService
    PaymentInterface <|.. NowPaymentsService
```
