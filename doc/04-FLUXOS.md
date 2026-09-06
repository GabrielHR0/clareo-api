# Clareo — Fluxos do Sistema

## Fluxo 1: Doação (Etapa 1 - Validar)

```
Doador                    Sistema                     Externo
  │                         │                           │
  │  1. Criar conta         │                           │
  │  (email, senha)         │                           │
  │ ──────────────────────> │                           │
  │                         │                           │
  │  2. Criar carteira      │                           │
  │     TRON                │                           │
  │ ──────────────────────> │ ───────────────────────> │ TronWeb Sidecar
  │                         │                           │
  │  3. Criar doação        │                           │
  │     (R$ valor)          │                           │
  │ ──────────────────────> │                           │
  │                         │  4. NOWPayments           │
  │                         │     cria pagamento        │
  │                         │ ───────────────────────> │
  │                         │                           │
  │  5. Retorna URL         │                           │
  │  de pagamento           │                           │
  │ <────────────────────── │                           │
  │                         │                           │
  │  6. Paga via PIX        │                           │
  │ ──────────────────────> │                           │
  │                         │                           │
  │                         │  7. Webhook NOWPayments   │
  │                         │ ───────────────────────> │
  │                         │                           │
  │                         │  8. Binance compra USDT   │
  │                         │     (0.1%)                │
  │                         │ ───────────────────────> │
  │                         │                           │
  │                         │  9. Envia USDT TRC-20     │
  │                         │     (~$1.44)              │
  │                         │ ───────────────────────> │ TRON Network
  │                         │                           │
  │  10. Confirmação        │                           │
  │ <────────────────────── │                           │
```

**Status da doação:**
- `pending` → Pagamento criado no NOWPayments
- `confirmed` → Pagamento recebido + USDT convertido + enviado
- `failed` → Erro na conversão ou envio

---

## Fluxo 2: Saque (Etapa 2 - Adicionar)

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
  │     Aave/wallet         │                           │
  │                         │ ───────────────────────> │ Aave V3
  │                         │                           │
  │  4. Redeem USDT         │                           │
  │     do Aave             │                           │
  │                         │ ───────────────────────> │
  │                         │                           │
  │  5. Vender USDT         │                           │
  │     (Binance API)       │                           │
  │                         │ ───────────────────────> │ Binance
  │                         │                           │
  │  6. Envia PIX           │                           │
  │     para beneficiário   │                           │
  │                         │ ───────────────────────> │ NOWPayments
  │                         │                           │
  │  7. Confirmação         │                           │
  │ <────────────────────── │                           │
```

**Status do saque:**
- `pending` → Solicitação criada
- `processing` → Em processamento (redeeming + vendendo)
- `completed` → PIX enviado
- `failed` → Erro no processamento

---

## Fluxo 3: Yield (Etapa 3 - Adicionar)

```
Sidekiq Job               Sistema                     Aave V3
  │                         │                           │
  │  1. Executa a cada 24h  │                           │
  │ ──────────────────────> │                           │
  │                         │                           │
  │  2. Consulta APY        │                           │
  │     atual               │                           │
  │                         │ ───────────────────────> │
  │                         │                           │
  │  3. Retorna APY         │                           │
  │                         │ <──────────────────────── │
  │                         │                           │
  │  4. Consulta saldo      │                           │
  │     de cada carteira    │                           │
  │                         │ ───────────────────────> │
  │                         │                           │
  │  5. Retorna saldo       │                           │
  │                         │ <──────────────────────── │
  │                         │                           │
  │  6. Calcula ganho       │                           │
  │     = saldo × APY/365   │                           │
  │                         │                           │
  │  7. Salva snapshot      │                           │
  │                         │                           │
  │  8. Atualiza saldo      │                           │
  │     wallet              │                           │
```

**Snapshot contém:**
- `balance` → Saldo naquele momento
- `apy` → APY do Aave
- `earned` → Ganhos acumulados
- `protocol` → Protocolo utilizado (aave, morpho)

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
  │ ────────────────────────> │ ──────────────────────> │
  │                           │                         │
  │  8. Retorna resposta      │                         │
  │ <──────────────────────── │                         │
```
