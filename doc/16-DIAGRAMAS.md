# Clareo — Diagramas de Fluxo

## 1. Visão Geral do Sistema

```mermaid
graph TB
    subgraph "Cliente"
        A[Browser/Mobile]
    end

    subgraph "Clareo API (Rails 8.1 + Puma)"
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
        J[Aave V3]
        K[Solana]
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
    C --> J
    C --> K
```

---

## 2. APIs Externas — O que cada uma faz

```mermaid
graph LR
    subgraph "NOWPayments (PIX Widget)"
        N1[BRL via PIX] -->|On-ramp| N2[USDT TRC-20]
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

    subgraph "Aave V3 (Yield)"
        J1[Deposita USDT] -->|Supply| J2[aUSDT]
        J2 -->|Withdraw| J3[Saca USDT]
        J4[APY 3-5%] -.->|Rendimento| J2
    end

    subgraph "Solana (Low-fee)"
        S1[Carteira] -->|Envia $0.0004| S2[USDT SPL]
        S2 -->|Recebe| S3[Carteira]
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
    participant Av as Aave V3

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

    A->>A: Atualiza saldo + cria snapshot

    opt Yield habilitado (Etapa 3)
        A->>Av: Deposita USDT
        Av-->>A: aUSDT
    end

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
    participant Av as Aave V3
    participant X as Binance
    participant N as NOWPayments

    B->>A: POST /withdrawals (valor R$)
    A->>A: Valida dados + calcula USDT necessário

    A->>Av: Consulta saldo Aave
    Av-->>A: saldo USDT

    alt Saldo suficiente
        A->>Av: Redeem USDT
        Av-->>A: txHash

        A->>X: Vende USDT para BRL (0.1%)
        X-->>A: BRL na conta Binance

        A->>N: Cria withdrawal USDT → PIX (0.5%)
        N-->>A: withdrawal_id

        N->>B: PIX enviado
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
   │          └── Sacando do Aave + convertendo
   └── Solicitação criada
```

---

## 5. Fluxo de Yield (Monitoramento)

```mermaid
sequenceDiagram
    participant S as Sidekiq Job
    participant A as Clareo API
    participant Av as Aave V3

    loop A cada 24h
        S->>A: YieldMonitorJob.perform
        A->>Av: Consulta APY atual
        Av-->>A: APY (ex: 4.5%)

        A->>Av: Consulta saldo de cada carteira
        Av-->>A: saldo USDT

        A->>A: Calcula ganho = saldo × APY/365
        A->>A: Salva YieldSnapshot
        A->>A: Atualiza saldo wallet

        alt Ganho > threshold
            A->>A: Notifica admin
        end
    end
```

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
        A->>A: Continua processamento
        A-->>C: Resposta
    end
```

---

## 7. Resumo das Integrações

| API | O que faz | Quando usa | Custo |
|-----|-----------|------------|-------|
| **NOWPayments** | On-ramp (PIX→USDT) | Doação | 0.5% |
| **Binance** | Compra/venda USDT | Doação + Saque | 0.1% |
| **TRON** | Blockchain, carteiras | Doação + Saque | ~$1.44 |
| **Aave V3** | Yield (deposito/saque) | Yield | Gas only |
| **Solana** | Low-fee transfers | Micro-transações | $0.0004 |
