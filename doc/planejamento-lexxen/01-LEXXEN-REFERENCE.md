# Lexxen API — Referências

## Documentação

| Recurso | Link |
|---------|------|
| API Docs | https://cashout.lexxen.com/docs |
| Sandbox | https://cashout.lexxen.com (chave `lxn_test_...`) |
| Postman Collection | https://cashout.lexxen.com/postman/Lexxen_Hub_API.postman_collection.json |
| LLM Reference | https://cashout.lexxen.com/docs/llms.md |

## Base URL

```
https://cashout.lexxen.com/api/v1
```

## Autenticação

Todos os endpoints usam HMAC-SHA256.

### Headers obrigatórios

| Header | Descrição |
|--------|-----------|
| `X-API-Key` | Chave do tenant (`lxn_...` em produção, `lxn_test_...` em sandbox) |
| `X-Timestamp` | Timestamp Unix em segundos |
| `X-Signature` | HMAC-SHA256 do payload |
| `Content-Type` | `application/json` |

### Payload da assinatura

```
TIMESTAMP + METHOD + PATH + BODY
```

- `METHOD` em maiúsculas
- `PATH` sem barra inicial e sem query string
- `BODY` = corpo cru (string vazia em GET)
- Timestamp válido por ±60 segundos

## Endpoints Principais

### On-ramp (PIX → USDT)

| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/quotes` | POST | Cria cotação (trava preço ~5 min) |
| `/orders` | POST | Cria pedido (gera PIX) |
| `/orders/{id}` | GET | Consulta status |

### Off-ramp (USDT → PIX)

| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/sell/quotes` | POST | Cria cotação de venda |
| `/sell/orders` | POST | Cria pedido de venda |
| `/sell/orders/{id}` | GET | Consulta status |

### Wallets

| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/wallets` | GET | Lista carteiras |
| `/wallets/validate` | POST | Valida endereço |

### Saldo

| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/balance` | GET | Saldo unificado (PIX + cripto) |
| `/balance/banking` | GET | Saldo no banking core |

## Webhooks

### Eventos

| Evento | Descrição |
|--------|-----------|
| `transaction.completed` | Operação concluída |
| `transaction.failed` | Falha na operação |

### Payload

```json
{
  "event": "transaction.completed",
  "order_uuid": "ord_3f1…77",
  "external_id": "pedido-loja-123",
  "direction": "on_ramp",
  "status": "completed",
  "asset": "USDT",
  "network": "polygon",
  "amount_brl": "200.00",
  "amount_crypto": "38.74000000",
  "wallet_address": "0x8f3…a91",
  "transaction_hash": null,
  "end_to_end_id": null
}
```

### Verificação HMAC

```ruby
expected = OpenSSL::HMAC.hexdigest('SHA256', api_secret, raw_body)
raise SecurityError unless Rack::Utils.secure_compare(expected, signature)
```

## Tipos

| Campo | Valores |
|-------|---------|
| `asset` | `USDT`, `USDC` |
| `network` | `polygon`, `ethereum`, `tron`, `solana` |
| `direction` | `on_ramp`, `off_ramp`, `wallet_transfer` |
| `display_status` | `awaiting_payment`, `awaiting_deposit`, `processing`, `completed`, `failed` |

## Taxas

| Operação | Taxa |
|----------|------|
| On-ramp | 3% + fixa + rede |
| Off-ramp | 1.5% + fixa + R$3.50 |
