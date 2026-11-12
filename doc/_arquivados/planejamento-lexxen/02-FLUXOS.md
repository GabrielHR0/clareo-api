# Clareo — Fluxos com Lexxen

## Visão Geral dos Fluxos

```
┌──────────┐     PIX      ┌──────────┐    USDT     ┌──────────┐
│  Doador  │ ───────────→ │  Clareo  │ ──────────→ │ Lexxen   │
│          │ ←─────────── │          │ ←────────── │ Hub API  │
└──────────┘   QR Code    └──────────┘   Webhook   └──────────┘
                                    │
                                    │ USDT → PIX
                                    ↓
                             ┌──────────┐
                             │Instituição│
                             └──────────┘
```

---

## Fluxo 1: Cadastro de Doador

```
┌─────────┐                          ┌─────────┐                          ┌─────────┐
│  Front  │                          │  Clareo │                          │ Lexxen  │
└────┬────┘                          └────┬────┘                          └────┬────┘
     │                                     │                                     │
     │  POST /api/v1/auth/register        │                                     │
     │  { name, email, password }         │                                     │
     │ ──────────────────────────────────→│                                     │
     │                                     │                                     │
     │                                     │  Valida dados                      │
     │                                     │  bcrypt(password)                  │
     │                                     │  Cria User no PG                   │
     │                                     │                                     │
     │                                     │  Gera JWT                          │
     │  { token, user }                   │                                     │
     │ ←──────────────────────────────────│                                     │
     │                                     │                                     │
```

**Status:** Usuário criado, pronto para criar carteira e doar.

---

## Fluxo 2: Criar Carteira

```
┌─────────┐                          ┌─────────┐                          ┌─────────┐
│  Front  │                          │  Clareo │                          │ Lexxen  │
└────┬────┘                          └────┬────┘                          └────┬────┘
     │                                     │                                     │
     │  POST /api/v1/wallets              │                                     │
     │  Authorization: Bearer <jwt>       │                                     │
     │  { network: "polygon" }            │                                     │
     │ ──────────────────────────────────→│                                     │
     │                                     │                                     │
     │                                     │  Valida JWT                        │
     │                                     │                                     │
     │                                     │  GET /wallets                      │
     │                                     │  ─────────────────────────────────→│
     │                                     │                                     │
     │                                     │  ← { wallets: [...] }              │
     │                                     │  ←─────────────────────────────────│
     │                                     │                                     │
     │                                     │  Salva wallet_id no PG             │
     │  { wallet }                         │                                     │
     │ ←──────────────────────────────────│                                     │
     │                                     │                                     │
```

**Status:** Carteira criada. USDT recebido será depositado nela.

---

## Fluxo 3: Receber Doação (On-ramp: PIX → USDT)

### 3.1 Iniciar Doação

```
┌─────────┐                          ┌─────────┐                          ┌─────────┐
│  Front  │                          │  Clareo │                          │ Lexxen  │
└────┬────┘                          └────┬────┘                          └────┬────┘
     │                                     │                                     │
     │  POST /api/v1/donations            │                                     │
     │  Authorization: Bearer <jwt>       │                                     │
     │  {                                 │                                     │
     │    amount_brl: 100.00,             │                                     │
     │    donor_name: "João",             │                                     │
     │    donor_email: "joao@email.com"   │                                     │
     │  }                                 │                                     │
     │ ──────────────────────────────────→│                                     │
     │                                     │                                     │
     │                                     │  Valida JWT + dados                 │
     │                                     │                                     │
     │                                     │  1. Cria Donation (status: pending) │
     │                                     │                                     │
     │                                     │  2. POST /quotes                   │
     │                                     │  { asset: "USDT",                   │
     │                                     │    network: "polygon",              │
     │                                     │    amount: 100.00 }                 │
     │                                     │  ─────────────────────────────────→│
     │                                     │                                     │
     │                                     │  ← { quote_id, amount_usdt,        │
     │                                     │      expires_at }                   │
     │                                     │  ←─────────────────────────────────│
     │                                     │                                     │
     │                                     │  3. Salva quote_id na Donation     │
     │                                     │                                     │
     │                                     │  4. POST /orders                   │
     │                                     │  { quote_id,                       │
     │                                     │    external_id: "donation_123" }    │
     │                                     │  ─────────────────────────────────→│
     │                                     │                                     │
     │                                     │  ← { order_id,                     │
     │                                     │      pix_copy_paste,               │
     │                                     │      pix_qr_code,                  │
     │                                     │      amount_brl,                   │
     │                                     │      amount_usdt,                  │
     │                                     │      expires_at }                   │
     │                                     │  ←─────────────────────────────────│
     │                                     │                                     │
     │                                     │  5. Atualiza Donation              │
     │                                     │     lexxen_order_id = order_id     │
     │                                     │     amount_usdt = 18.5185          │
     │                                     │     status: pending                │
     │                                     │                                     │
     │  { donation_id, pix_copy_paste,    │                                     │
     │    pix_qr_code, amount_brl,        │                                     │
     │    amount_usdt, expires_at }       │                                     │
     │ ←──────────────────────────────────│                                     │
     │                                     │                                     │
```

### 3.2 Doador Paga PIX

```
┌─────────┐                          ┌─────────┐                          ┌─────────┐
│  Doador │                          │  Clareo │                          │ Lexxen  │
└────┬────┘                          └────┬────┘                          └────┬────┘
     │                                     │                                     │
     │  Copia pix_copy_paste              │                                     │
     │  ou escaneia QR Code               │                                     │
     │                                     │                                     │
     │  Paga R$ 100,00 via PIX            │                                     │
     │ ──────────────────────────────────→│ (banco)                             │
     │                                     │                                     │
     │                                     │                                     │
```

### 3.3 Webhook: Pagamento Confirmado

```
┌─────────┐                          ┌─────────┐                          ┌─────────┐
│ Lexxen  │                          │  Clareo │                          │  PG     │
└────┬────┘                          └────┬────┘                          └────┬────┘
     │                                     │                                     │
     │  POST /api/v1/webhooks/lexxen      │                                     │
     │  X-Signature: <hmac>               │                                     │
     │  {                                 │                                     │
     │    event: "transaction.completed", │                                     │
     │    order_uuid: "ord_3f1…77",       │                                     │
     │    direction: "on_ramp",           │                                     │
     │    status: "completed",            │                                     │
     │    asset: "USDT",                  │                                     │
     │    network: "polygon",             │                                     │
     │    amount_brl: "100.00",           │                                     │
     │    amount_crypto: "18.51850000",   │                                     │
     │    wallet_address: "0x8f3…a91",    │                                     │
     │    transaction_hash: "0xabc…def"   │                                     │
     │  }                                 │                                     │
     │ ──────────────────────────────────→│                                     │
     │                                     │                                     │
     │                                     │  1. Verifica HMAC-SHA256            │
     │                                     │     expected = HMAC(secret, body)   │
     │                                     │     raise unless secure_compare     │
     │                                     │                                     │
     │                                     │  2. Busca Donation por              │
     │                                     │     lexxen_order_id                 │
     │                                     │                                     │
     │                                     │  3. Atualiza Donation               │
     │                                     │     status: completed               │
     │                                     │     amount_usdt: 18.5185            │
     │                                     │     tx_hash: 0xabc…def              │
     │                                     │                                     │
     │                                     │  4. Atualiza Wallet saldo           │
     │                                     │     saldo += 18.5185 USDT           │
     │                                     │                                     │
     │  200 OK                             │                                     │
     │ ←──────────────────────────────────│                                     │
     │                                     │                                     │
```

### 3.4 Consulta Status (polling)

```
┌─────────┐                          ┌─────────┐                          ┌─────────┐
│  Front  │                          │  Clareo │                          │ Lexxen  │
└────┬────┘                          └────┬────┘                          └────┬────┘
     │                                     │                                     │
     │  GET /api/v1/donations/:id         │                                     │
     │ ──────────────────────────────────→│                                     │
     │                                     │                                     │
     │                                     │  GET /orders/{id}                   │
     │                                     │  ─────────────────────────────────→│
     │                                     │  ← { status: "completed" }          │
     │                                     │  ←─────────────────────────────────│
     │                                     │                                     │
     │  { donation: { status,             │                                     │
     │    amount_usdt, tx_hash } }        │                                     │
     │ ←──────────────────────────────────│                                     │
     │                                     │                                     │
```

---

## Fluxo 4: Solicitar Saque (Off-ramp: USDT → PIX)

### 4.1 Instituição Solicita Saque

```
┌──────────────┐                    ┌─────────┐                          ┌─────────┐
│  Instituição │                    │  Clareo │                          │ Lexxen  │
└──────┬───────┘                    └────┬────┘                          └────┬────┘
       │                                 │                                     │
       │  POST /api/v1/withdrawals      │                                     │
       │  Authorization: Bearer <jwt>   │                                     │
       │  {                             │                                     │
       │    amount_brl: 100.00,         │                                     │
       │    pix_key: "chave@email.com"  │                                     │
       │  }                             │                                     │
       │ ──────────────────────────────→│                                     │
       │                                 │                                     │
       │                                 │  Valida JWT + role == institution    │
       │                                 │                                     │
       │                                 │  1. Verifica saldo wallet >= 100    │
       │                                 │                                     │
       │                                 │  2. Cria Withdrawal (status:        │
       │                                 │     pending)                        │
       │                                 │                                     │
       │                                 │  3. Calcula USDT necessário:        │
       │                                 │     100 / 0.985 = 101.52 USDT      │
       │                                 │     (1.5% off-ramp fee)             │
       │                                 │                                     │
       │                                 │  4. POST /sell/quotes               │
       │                                 │  { asset: "USDT",                   │
       │                                 │    network: "polygon",              │
       │                                 │    amount: 101.52 }                 │
       │                                 │  ─────────────────────────────────→│
       │                                 │                                     │
       │                                 │  ← { quote_id, amount_brl,         │
       │                                 │      fee, expires_at }              │
       │                                 │  ←─────────────────────────────────│
       │                                 │                                     │
       │                                 │  5. Salva quote_id na Withdrawal    │
       │                                 │                                     │
       │                                 │  6. POST /sell/orders               │
       │                                 │  { quote_id,                       │
       │                                 │    sender_address: "0x8f3…",        │
       │                                 │    receiver_pix_key:                │
       │                                 │      "chave@email.com",            │
       │                                 │    external_id: "withdrawal_456" }  │
       │                                 │  ─────────────────────────────────→│
       │                                 │                                     │
       │                                 │  ← { order_id,                     │
       │                                 │      deposit_address,               │
       │                                 │      amount_usdt,                   │
       │                                 │      amount_brl,                    │
       │                                 │      fee }                          │
       │                                 │  ←─────────────────────────────────│
       │                                 │                                     │
       │                                 │  7. Atualiza Withdrawal             │
       │                                 │     lexxen_order_id = order_id      │
       │                                 │     amount_usdt = 101.52            │
       │                                 │     status: awaiting_deposit        │
       │                                 │                                     │
       │  { withdrawal_id,               │                                     │
       │    deposit_address,             │                                     │
       │    amount_usdt,                 │                                     │
       │    amount_brl,                  │                                     │
       │    fee, expires_at }            │                                     │
       │ ←───────────────────────────────│                                     │
       │                                 │                                     │
```

### 4.2 Transferência USDT para Lexxen

```
┌──────────────┐                    ┌─────────┐                          ┌─────────┐
│  Instituição │                    │  Clareo │                          │ Lexxen  │
└──────┬───────┘                    └────┬────┘                          └────┬────┘
       │                                 │                                     │
       │  Admin transfere USDT           │                                     │
       │  do wallet do Clareo            │                                     │
       │  para deposit_address           │                                     │
       │ ──────────────────────────────→│ (blockchain)                         │
       │                                 │                                     │
       │                                 │                                     │
       │                                 │  Lexxen detecta depósito            │
       │                                 │  na deposit_address                 │
       │                                 │  (Polygon, ~2s confirmação)         │
       │                                 │                                     │
```

### 4.3 Webhook: Saque Processado

```
┌─────────┐                          ┌─────────┐                          ┌─────────┐
│ Lexxen  │                          │  Clareo │                          │  PIX    │
└────┬────┘                          └────┬────┘                          └────┬────┘
     │                                     │                                     │
     │  POST /api/v1/webhooks/lexxen      │                                     │
     │  X-Signature: <hmac>               │                                     │
     │  {                                 │                                     │
     │    event: "transaction.completed", │                                     │
     │    order_uuid: "ord_789…xyz",      │                                     │
     │    direction: "off_ramp",          │                                     │
     │    status: "completed",            │                                     │
     │    asset: "USDT",                  │                                     │
     │    network: "polygon",             │                                     │
     │    amount_brl: "100.00",           │                                     │
     │    amount_crypto: "101.52000000",  │                                     │
     │    transaction_hash: "0xdef…abc"   │                                     │
     │  }                                 │                                     │
     │ ──────────────────────────────────→│                                     │
     │                                     │                                     │
     │                                     │  1. Verifica HMAC-SHA256            │
     │                                     │                                     │
     │                                     │  2. Busca Withdrawal por            │
     │                                     │     lexxen_order_id                 │
     │                                     │                                     │
     │                                     │  3. Atualiza Withdrawal             │
     │                                     │     status: completed               │
     │                                     │     tx_hash: 0xdef…abc              │
     │                                     │                                     │
     │                                     │  4. Deduz wallet saldo              │
     │                                     │     saldo -= 101.52 USDT            │
     │                                     │                                     │
     │  200 OK                             │                                     │
     │ ←──────────────────────────────────│                                     │
     │                                     │                                     │
     │                                     │  Lexxen envia PIX                   │
     │                                     │  para receiver_pix_key              │
     │                                     │  ─────────────────────────────────→│
     │                                     │                                     │
```

---

## Fluxo 5: Verificação de Saldo

```
┌─────────┐                          ┌─────────┐                          ┌─────────┐
│  Front  │                          │  Clareo │                          │ Lexxen  │
└────┬────┘                          └────┬────┘                          └────┬────┘
     │                                     │                                     │
     │  GET /api/v1/wallets               │                                     │
     │ ──────────────────────────────────→│                                     │
     │                                     │                                     │
     │                                     │  GET /balance                       │
     │                                     │  ─────────────────────────────────→│
     │                                     │  ← { pix: 500.00,                  │
     │                                     │      usdt: 185.18,                  │
     │                                     │      usdc: 0 }                      │
     │                                     │  ←─────────────────────────────────│
     │                                     │                                     │
     │  { wallets: [{                     │                                     │
     │    id, network, address,           │                                     │
     │    balance_usdt: 185.18,           │                                     │
     │    balance_brl: 500.00             │                                     │
     │  }] }                              │                                     │
     │ ←──────────────────────────────────│                                     │
     │                                     │                                     │
```

---

## Fluxo 6: Consulta de Cotação (On-ramp)

```
┌─────────┐                          ┌─────────┐                          ┌─────────┐
│  Front  │                          │  Clareo │                          │ Lexxen  │
└────┬────┘                          └────┬────┘                          └────┬────┘
     │                                     │                                     │
     │  POST /api/v1/quotes/preview       │                                     │
     │  { amount_brl: 500.00 }            │                                     │
     │ ──────────────────────────────────→│                                     │
     │                                     │                                     │
     │                                     │  POST /quotes                       │
     │                                     │  { asset: "USDT",                   │
     │                                     │    network: "polygon",              │
     │                                     │    amount: 500.00 }                 │
     │                                     │  ─────────────────────────────────→│
     │                                     │                                     │
     │                                     │  ← { quote_id,                     │
     │                                     │      amount_usdt: 91.74,           │
     │                                     │      rate: 5.45,                    │
     │                                     │      fee: 15.00,                    │
     │                                     │      expires_at: "..." }            │
     │                                     │  ←─────────────────────────────────│
     │                                     │                                     │
     │  { amount_brl: 500.00,             │                                     │
     │    amount_usdt: 91.74,             │                                     │
     │    rate: 5.45,                     │                                     │
     │    fee: 15.00,                     │                                     │
     │    expires_at: "..." }             │                                     │
     │ ←──────────────────────────────────│                                     │
     │                                     │                                     │
```

---

## Fluxo 7: Webhook - Transação Falhou

```
┌─────────┐                          ┌─────────┐                          ┌─────────┐
│ Lexxen  │                          │  Clareo │                          │  Logs   │
└────┬────┘                          └────┬────┘                          └────┬────┘
     │                                     │                                     │
     │  POST /api/v1/webhooks/lexxen      │                                     │
     │  {                                 │                                     │
     │    event: "transaction.failed",    │                                     │
     │    order_uuid: "ord_3f1…77",       │                                     │
     │    status: "failed"                │                                     │
     │  }                                 │                                     │
     │ ──────────────────────────────────→│                                     │
     │                                     │                                     │
     │                                     │  1. Verifica HMAC                   │
     │                                     │                                     │
     │                                     │  2. Busca Donation/Withdrawal       │
     │                                     │                                     │
     │                                     │  3. Atualiza status: failed         │
     │                                     │                                     │
     │                                     │  4. Log erro                        │
     │                                     │  ─────────────────────────────────→│
     │                                     │                                     │
     │  200 OK                             │                                     │
     │ ←──────────────────────────────────│                                     │
     │                                     │                                     │
```

---

## Estados das Transações

### Donation (On-ramp)

```
pending → processing → completed
    │          │           │
    │          └─────→ failed
    └────────────────→ failed
```

| Estado | Descrição |
|--------|-----------|
| `pending` | Cotação criada, aguardando pagamento PIX |
| `processing` | PIX recebido, conversão em andamento |
| `completed` | USDT creditado na wallet |
| `failed` | Erro na conversão ou timeout |

### Withdrawal (Off-ramp)

```
pending → awaiting_deposit → processing → completed
    │            │               │            │
    │            └───────────────┴─────→ failed
    └──────────────────────────────────→ failed
```

| Estado | Descrição |
|--------|-----------|
| `pending` | Solicitação criada |
| `awaiting_deposit` | Aguardando depósito USDT na deposit_address |
| `processing` | USDT recebido, conversão para BRL em andamento |
| `completed` | PIX enviado para a chave PIX |
| `failed` | Erro na conversão ou envio |

---

## Tratamento de Erros

### Erro na Criação de Cotação

```ruby
# LexxenService#create_quote
def create_quote(amount_brl:, asset:, network:, wallet_address:)
  response = signed_request('POST', '/quotes', body: {
    asset: asset,
    network: network,
    amount: amount_brl
  }.to_json)

  case response['code']
  when 'QUOTE_EXPIRED'
    raise LexxenError, "Cotação expirada. Tente novamente."
  when 'INSUFFICIENT_LIQUIDITY'
    raise LexxenError, "Liquidez insuficiente para este valor."
  when 'INVALID_WALLET'
    raise LexxenError, "Endereço de wallet inválido."
  else
    response
  end
end
```

### Erro no Webhook

```ruby
# WebhooksController#lexxen
def lexxen
  unless LexxenService.verify_webhook(
    signature: request.headers['X-Signature'],
    body: request.body.read
  )
    render json: { error: "Invalid signature" }, status: :unauthorized
    return
  end

  event = params[:event]
  order_id = params[:order_uuid]

  case event
  when 'transaction.completed'
    handle_completed(order_id, params)
  when 'transaction.failed'
    handle_failed(order_id, params)
  else
    Rails.logger.warn "Unknown Lexxen event: #{event}"
  end

  head :ok
end
```

### Retry de Webhook

```ruby
# O Lexxen pode reenviar webhooks se não receber 200
# Idempotência: verificar se a transação já foi processada

def handle_completed(order_id, params)
  donation = Donation.find_by(lexxen_order_id: order_id)
  return if donation&.completed?  # Já processado

  # Processar...
end
```

---

## Segurança

### Validação HMAC

```ruby
def self.verify_webhook(signature:, body:)
  api_secret = ENV['LEXXEN_API_SECRET']
  expected = OpenSSL::HMAC.hexdigest('SHA256', api_secret, body)
  Rack::Utils.secure_compare(expected, signature)
end
```

### Proteção Contra Replay

```ruby
# Timestamp deve ser ±60 segundos
def valid_timestamp?(timestamp)
  Time.at(timestamp.to_i).utc.between?
    60.seconds.ago,
    60.seconds.from_now
end
```

### Idempotência

```ruby
# External_id único por transação
# Lexxen retorna o mesmo order_id se o mesmo external_id for enviado
def create_donation(params)
  external_id = "donation_#{SecureRandom.uuid}"
  # ... criar order com external_id
end
```
