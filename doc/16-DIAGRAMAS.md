# Clareo — Diagramas de Fluxo

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
        J[JustLend]
    end

    A -->|HTTP/2| B
    B --> C
    C --> D
    C --> E
    C --> F
    F --> C
    C --> G
    C --> H
    C --> I
    C --> J
```

---

## 2. APIs Externas — O que cada uma faz

```mermaid
graph LR
    subgraph "NOWPayments (On/Off-ramp)"
        N1[BRL via PIX] -->|On-ramp| N2[USDT TRC-20]
        N3[USDT TRC-20] -->|Off-ramp| N4[PIX para beneficiário]
    end

    subgraph "Binance (Exchange)"
        B1[BRL] -->|Compra| B2[USDT]
        B2 -->|Vende| B3[BRL]
        B4[Cotação USDT/BRL] -.->|Consulta| B5[GET /api/v3/ticker/price]
    end

    subgraph "TRON (Blockchain)"
        T1[Carteira] -->|Envia| T2[USDT TRC-20]
        T2 -->|Recebe| T3[Carteira]
        T4[Staking TRX] -.->|Gas grátis| T1
    end

    subgraph "JustLend (Yield)"
        J1[Deposita USDT] -->|Supply| J2[cTokens]
        J2 -->|Redeem| J3[Saca USDT]
        J4[APY ~1.35%] -.->|Rendimento| J2
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
    participant T as TRON Sidecar
    participant J as JustLend

    D->>A: POST /donations (valor R$)
    A->>A: Valida dados
    A->>N: Cria pagamento (BRL → USDT)
    N-->>A: payment_url + payment_id
    A-->>D: Retorna URL de pagamento

    D->>N: Paga via PIX/Cartão
    N->>N: Processa pagamento

    N->>A: Webhook: payment_status=finished
    A->>A: Verifica assinatura IPN

    A->>B: Compra USDT (POST /api/v3/order)
    B-->>A: orderId + USDT comprado

    A->>T: Envia USDT TRC-20 para carteira
    T-->>A: txHash

    A->>J: Deposita USDT (supply)
    J-->>A: txHash

    A->>A: Atualiza saldo + cria snapshot
    A-->>D: Confirmação (email/webhook)
```

### Status da Doação

```
pending → confirmed → failed
   │          │
   │          └── USDT convertido e depositado
   └── Pagamento criado no NOWPayments
```

---

## 4. Fluxo de Saque (Passo a passo)

```mermaid
sequenceDiagram
    participant B as Beneficiário
    participant A as Clareo API
    participant J as JustLend
    participant T as TRON Sidecar
    participant X as Binance
    participant P as NOWPayments (Off-ramp)

    B->>A: POST /withdrawals (valor R$)
    A->>A: Valida dados + calcula USDT necessário

    A->>J: Consulta saldo JustLend
    J-->>A: saldo USDT

    alt Saldo suficiente
        A->>J: Redeem USDT do JustLend
        J-->>A: txHash

        A->>T: Envia USDT da carteira JustLend para Binance
        T-->>A: txHash

        A->>X: Vende USDT para BRL
        X-->>A: BRL na conta Binance

        A->>P: Cria withdrawal (USDT → PIX)
        P-->>A: withdrawal_id

        P->>B: PIX enviado
        A-->>B: Confirmação
    else Saldo insuficiente
        A-->>B: Erro: saldo insuficiente
    end
```

### Status do Saque

```
pending → processing → completed → failed
   │          │           │
   │          │           └── PIX enviado
   │          └── Sacando do JustLend + convertendo
   └── Solicitação criada
```

---

## 5. Fluxo de Yield (Monitoramento)

```mermaid
sequenceDiagram
    participant S as Sidekiq Job
    participant A as Clareo API
    participant J as JustLend

    loop A cada 24h
        S->>A: YieldMonitorJob.perform
        A->>J: Consulta APY atual
        J-->>A: APY (ex: 1.35%)

        A->>J: Consulta saldo de cada carteira
        J-->>A: saldo USDT

        A->>A: Calcula ganho = saldo × APY/365
        A->>A: Salva YieldSnapshot
        A->>A: Atualiza saldo wallet

        alt Ganho > threshold
            A->>A: Notifica admin
        end
    end
```

### Snapshot contém

| Campo | Descrição |
|-------|-----------|
| `balance` | Saldo naquele momento |
| `apy` | APY do JustLend |
| `earned` | Ganhos acumulados |
| `date` | Data do snapshot |

---

## 6. Fluxo de Autenticação

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
        A->>R: Verifica se token está na blacklist
        R-->>A: não está
        A->>A: Continua processamento
        A-->>C: Resposta
    end

    C->>A: POST /auth/logout
    A->>R: Adiciona token à blacklist (TTL: 24h)
    A-->>C: { status: "logged_out" }
```

---

## 7. Arquitetura de Services

```mermaid
graph TB
    subgraph "Controllers"
        AC[AuthController]
        DC[DonationsController]
        WC[WalletsController]
        WDC[WithdrawalsController]
        YC[YieldController]
        WHC[WebhooksController]
    end

    subgraph "Services"
        AS[AuthService]
        DS[DonationService]
        BS[BinanceService]
        TS[TronService]
        JS[JustLendService]
        NS[NowPaymentsService]
        WS[WithdrawalService]
        YS[YieldService]
    end

    subgraph "Jobs"
        DCJ[DonationConfirmJob]
        WPJ[WebhookProcessJob]
        YMJ[YieldMonitorJob]
        WDPJ[WithdrawalProcessJob]
    end

    AC --> AS
    DC --> DS
    WC --> TS
    WDC --> WS
    YC --> YS
    WHC --> WPJ

    DS --> BS
    DS --> TS
    DS --> JS
    DS --> NS
    WS --> BS
    WS --> JS
    WS --> NS
    YS --> JS

    WPJ --> DCJ
    WPJ --> WDPJ
    YMJ --> YS
```

---

## 8. Diagrama de Deploy

```mermaid
graph TB
    subgraph "Produção"
        K[Kino Server]
        R[Rails API]
        S[Sidekiq Worker]
        PG[(PostgreSQL)]
        RD[(Redis)]
        NS[Node.js Sidecar]
    end

    subgraph "Externos"
        B[Binance API]
        T[TRON Network]
        J[JustLend]
        N[NOWPayments]
    end

    K --> R
    R --> PG
    R --> RD
    S --> RD
    S --> R
    R --> NS
    NS --> T
    NS --> J
    R --> B
    R --> N
```

---

## Resumo das Integrações

| API | O que faz | Quando usa | Custo |
|-----|-----------|------------|-------|
| **NOWPayments** | On-ramp (PIX→USDT) e Off-ramp (USDT→PIX) | Doação + Saque | 1-2% |
| **Binance** | Compra/venda USDT, cotação | Doação + Saque | 0.1% |
| **TRON** | Blockchain, carteiras, transferências | Doação + Saque | ~$0.01 |
| **JustLend** | Yield (deposito/saque USDT) | Yield + Saque | Gas only |
