# Clareo — Fluxos do Sistema

## Fluxo 1: Doação (Deposit Flow)

```
Doador                    Sistema                     Blockchain
  │                         │                           │
  │  1. Seleciona método    │                           │
  │  (PIX/Cartão)           │                           │
  │ ──────────────────────> │                           │
  │                         │                           │
  │  2. Cria pagamento      │                           │
  │     NOWPayments         │                           │
  │ ──────────────────────> │                           │
  │                         │                           │
  │  3. Redireciona para    │                           │
  │     pagamento           │                           │
  │ <────────────────────── │                           │
  │                         │                           │
  │  4. Pagamento aprovado  │                           │
  │ ──────────────────────> │                           │
  │                         │                           │
  │                         │  5. Webhook NOWPayments    │
  │                         │ ────────────────────────> │
  │                         │                           │
  │                         │  6. Compra USDT           │
  │                         │     (Binance API)         │
  │                         │                           │
  │                         │  7. Envia USDT TRC-20     │
  │                         │     (TronWeb)             │
  │                         │ ────────────────────────> │
  │                         │                           │
  │                         │  8. Deposita em JustLend  │
  │                         │     (Yield)               │
  │                         │ ────────────────────────> │
  │                         │                           │
  │  9. Confirmação via     │                           │
  │     email/webhook       │                           │
  │ <────────────────────── │                           │
```

**Status da doação:**
- `pending` → Pagamento criado
- `confirmed` → Pagamento recebido + USDT convertido
- `failed` → Erro na conversão ou envio

---

## Fluxo 2: Saque (Withdrawal Flow)

```
Beneficiário               Sistema                     Externo
  │                         │                           │
  │  1. Solicita saque      │                           │
  │     (R$ valor)          │                           │
  │ ──────────────────────> │                           │
  │                         │                           │
  │  2. Calcula USDT        │                           │
  │     necessário          │                           │
  │                         │                           │
  │  3. Verifica saldo      │                           │
  │     JustLend            │                           │
  │                         │ ────────────────────────> │
  │                         │                           │
  │  4. Sacar USDT          │                           │
  │     do JustLend         │                           │
  │                         │ ────────────────────────> │
  │                         │                           │
  │  5. Vender USDT         │                           │
  │     (Binance API)       │                           │
  │                         │                           │
  │  6. Envia PIX           │                           │
  │     para beneficiário   │                           │
  │                         │ ────────────────────────> │
  │                         │                           │
  │  7. Confirmação via     │                           │
  │     email/webhook       │                           │
  │ <────────────────────── │                           │
```

**Status do saque:**
- `pending` → Solicitação criada
- `processing` → Em processamento
- `completed` → PIX enviado
- `failed` → Erro no processamento

---

## Fluxo 3: Yield (Yield Flow)

```
Sidekiq Job               Sistema                     JustLend
  │                         │                           │
  │  1. Executa a cada 24h  │                           │
  │ ──────────────────────> │                           │
  │                         │                           │
  │  2. Consulta APY        │                           │
  │     atual               │                           │
  │                         │ ────────────────────────> │
  │                         │                           │
  │  3. Retorna APY         │                           │
  │                         │ <──────────────────────── │
  │                         │                           │
  │  4. Calcula ganho       │                           │
  │     = saldo × APY/365   │                           │
  │                         │                           │
  │  5. Salva snapshot      │                           │
  │                         │                           │
  │  6. Atualiza saldo      │                           │
  │     wallet              │                           │
  │                         │                           │
  │  7. Notifica admin      │                           │
  │     se ganho > threshold│                           │
  │                         │                           │
```

**Snapshot contém:**
- `balance` → Saldo naquele momento
- `apy` → APY do JustLend
- `earned` → Ganhos acumulados

---

## Fluxo 4: Conversão BRL → USDT

```
Sistema                    Binance API
  │                           │
  │  1. GET /api/v3/ticker/price
  │     ?symbol=USDTBRL       │
  │ ────────────────────────> │
  │                           │
  │  2. Retorna preço         │
  │     ex: 5.05              │
  │ <──────────────────────── │
  │                           │
  │  3. Aplica spread (0.2%)  │
  │     Preço final: 5.06     │
  │                           │
  │  4. Calcula USDT:         │
  │     R$100 / 5.06 = 19.76  │
  │     USDT                  │
  │                           │
  │  5. Cria ordem de compra  │
  │     POST /api/v3/order    │
  │ ────────────────────────> │
  │                           │
```

---

## Fluxo 5: Autenticação

```
Cliente                    Rails API                  Redis
  │                           │                         │
  │  1. POST /auth/login      │                         │
  │     (email, password)     │                         │
  │ ────────────────────────> │                         │
  │                           │                         │
  │  2. Busca usuário         │                         │
  │     no PostgreSQL         │                         │
  │                           │                         │
  │  3. Verifica senha        │                         │
  │     (bcrypt)              │                         │
  │                           │                         │
  │  4. Gera JWT token        │                         │
  │     (expira em 24h)       │                         │
  │                           │                         │
  │  5. Retorna token         │                         │
  │ <──────────────────────── │                         │
  │                           │                         │
  │  6. Envia token           │                         │
  │     em cada request       │                         │
  │     Authorization: Bearer │                         │
  │ ────────────────────────> │                         │
  │                           │                         │
  │  7. Valida JWT            │                         │
  │     e verifica se não     │                         │
  │     está na blacklist     │                         │
  │                           │ ──────────────────────> │
  │                           │                         │
  │  8. Retorna resposta      │                         │
  │ <──────────────────────── │                         │
```
