# Clareo — API Endpoints

## Base URL

```
https://api.clareo.com.br/api/v1
```

## Autenticação

Todos os endpoints (exceto login/register) requerem header:

```
Authorization: Bearer <token>
```

---

## Auth

### POST /auth/login

Realiza login e retorna token JWT.

**Request:**
```json
{
  "email": "usuario@exemplo.com",
  "password": "senha123"
}
```

**Response (200):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "usuario@exemplo.com",
    "name": "João Silva",
    "role": "donor"
  }
}
```

**Response (401):**
```json
{
  "error": "Email ou senha inválidos"
}
```

---

### POST /auth/register

Registra novo usuário.

**Request:**
```json
{
  "email": "novo@exemplo.com",
  "name": "Maria Santos",
  "password": "senha123",
  "password_confirmation": "senha123"
}
```

**Response (201):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 2,
    "email": "novo@exemplo.com",
    "name": "Maria Santos",
    "role": "donor"
  }
}
```

---

## Donations

### POST /donations

Cria nova doação.

**Request:**
```json
{
  "donor_name": "João Silva",
  "donor_email": "joao@exemplo.com",
  "amount_brl": 100.00,
  "payment_method": "pix"
}
```

**Response (201):**
```json
{
  "id": 1,
  "status": "pending",
  "amount_brl": 100.00,
  "amount_usdt": 19.76,
  "fee_amount": 2.00,
  "payment_url": "https://nowpayments.io/payment?invoice_id=...",
  "created_at": "2025-01-15T10:30:00Z"
}
```

---

### GET /donations/:id

Busca doação por ID.

**Response (200):**
```json
{
  "id": 1,
  "donor_name": "João Silva",
  "donor_email": "joao@exemplo.com",
  "amount_brl": 100.00,
  "amount_usdt": 19.76,
  "fee_amount": 2.00,
  "status": "confirmed",
  "tx_hash": "abc123...",
  "payment_method": "pix",
  "created_at": "2025-01-15T10:30:00Z",
  "confirmed_at": "2025-01-15T10:32:00Z"
}
```

---

### GET /donations

Lista doações do usuário autenticado.

**Query Params:**
- `page` (default: 1)
- `per_page` (default: 20, max: 100)
- `status` (pending, confirmed, failed)

**Response (200):**
```json
{
  "donations": [...],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 100
  }
}
```

---

## Wallets

### GET /wallets

Lista carteiras do usuário.

**Response (200):**
```json
{
  "wallets": [
    {
      "id": 1,
      "address": "TSEHe6DwQUMfBkqXJsRCNFyU8d9p2qaxBZ",
      "balance_usdt": 150.25,
      "network": "tron",
      "active": true,
      "created_at": "2025-01-15T10:30:00Z"
    }
  ]
}
```

---

### POST /wallets

Cria nova carteira.

**Response (201):**
```json
{
  "id": 2,
  "address": "TnewAddress...",
  "balance_usdt": 0.0,
  "network": "tron",
  "active": true,
  "created_at": "2025-01-15T11:00:00Z"
}
```

---

## Withdrawals

### POST /withdrawals

Solicita saque.

**Request:**
```json
{
  "wallet_id": 1,
  "amount_brl": 50.00,
  "pix_key": "usuario@exemplo.com"
}
```

**Response (201):**
```json
{
  "id": 1,
  "status": "pending",
  "amount_brl": 50.00,
  "amount_usdt": 9.88,
  "pix_key": "usuario@exemplo.com",
  "created_at": "2025-01-15T12:00:00Z"
}
```

---

### GET /withdrawals/:id

Busca saque por ID.

**Response (200):**
```json
{
  "id": 1,
  "status": "completed",
  "amount_brl": 50.00,
  "amount_usdt": 9.88,
  "tx_hash": "def456...",
  "pix_key": "usuario@exemplo.com",
  "created_at": "2025-01-15T12:00:00Z",
  "completed_at": "2025-01-15T12:05:00Z"
}
```

---

### GET /withdrawals

Lista saques do usuário.

**Query Params:**
- `page` (default: 1)
- `per_page` (default: 20, max: 100)
- `status` (pending, processing, completed, failed)

**Response (200):**
```json
{
  "withdrawals": [...],
  "meta": {
    "current_page": 1,
    "total_pages": 2,
    "total_count": 35
  }
}
```

---

## Yield

### GET /yield/snapshots

Lista snapshots de rendimento.

**Query Params:**
- `wallet_id` (obrigatório)
- `start_date` (ISO 8601)
- `end_date` (ISO 8601)

**Response (200):**
```json
{
  "snapshots": [
    {
      "id": 1,
      "balance": 150.25,
      "apy": 1.35,
      "earned": 0.56,
      "recorded_at": "2025-01-15T00:00:00Z"
    }
  ]
}
```

---

### GET /yield/summary

Retorna resumo de rendimento.

**Response (200):**
```json
{
  "total_balance": 150.25,
  "current_apy": 1.35,
  "total_earned": 12.50,
  "earned_today": 0.56,
  "earned_this_month": 5.25
}
```

---

## Webhooks

### POST /webhooks/nowpayments

Webhook do NOWPayments (IPN).

**Headers:**
- `x-nowpayments-sig`: Assinatura HMAC-SHA512

**Request:**
```json
{
  "id": 12345,
  "order_id": "donation_abc123",
  "payment_status": "finished",
  "price_amount": 100.00,
  "price_currency": "brl",
  "amount": 19.76,
  "amount_currency": "usdttrc20"
}
```

**Response (200):**
```json
{
  "status": "ok"
}
```

---

## Erros

### Formato padrão

```json
{
  "error": "Mensagem de erro"
}
```

### Códigos de status

| Código | Descrição |
|--------|-----------|
| 200 | Sucesso |
| 201 | Criado |
| 400 | Requisição inválida |
| 401 | Não autenticado |
| 403 | Não autorizado |
| 404 | Não encontrado |
| 422 | Entidade não processável |
| 429 | Rate limit excedido |
| 500 | Erro interno |
