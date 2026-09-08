# Lexxen API — Referência

## Empresa

| Item | Detalhe |
|------|---------|
| Empresa | LEXXEN LTDA |
| CNPJ | 63.987.111/0001-53 |
| Contato | support@lexxen.com · WhatsApp: +55 800-000-4531 |
| Regulação | Licença crypto-as-a-service; KYC/AML/PLD-FT |

> A Lexxen é provedora de tecnologia. Os serviços financeiros são prestados por instituições parceiras autorizadas.

---

## Links

| Recurso | Link |
|---------|------|
| API Docs | https://cashout.lexxen.com/docs |
| API Docs (LLM) | https://cashout.lexxen.com/docs/llms.md |
| Postman Collection | https://cashout.lexxen.com/postman/Lexxen_Hub_API.postman_collection.json |
| Sandbox | https://cashout.lexxen.com (chave `lxn_test_...`) |
| Registro conta | https://www.lexxen.com/register |
| Termos de Uso | https://www.lexxen.com/terms |
| Política de Privacidade | https://www.lexxen.com/privacy |

---

## Base URL

```
https://cashout.lexxen.com/api/v1
```

---

## Autenticação (HMAC-SHA256)

**Headers obrigatórios:**

| Header | Descrição |
|--------|-----------|
| `X-API-Key` | Chave do tenant (`lxn_...` prod, `lxn_test_...` sandbox) |
| `X-Timestamp` | Timestamp Unix em segundos |
| `X-Signature` | HMAC-SHA256 do payload |
| `Content-Type` | `application/json` |

**Payload da assinatura:**

```
TIMESTAMP + METHOD + PATH + BODY
```

- `METHOD` em maiúsculas
- `PATH` sem barra inicial, sem query string
- `BODY` = corpo cru (string vazia em GET)
- Timestamp válido por ±60 segundos

---

## Endpoints

### On-ramp (PIX → USDT)

| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/quotes` | POST | Cria cotação (trava preço ~5 min) |
| `/orders` | POST | Cria pedido (gera PIX) |
| `/orders/{id}` | GET | Consulta status |

**Fluxo:**
1. POST `/quotes` → retorna `quote_id` e valor USDT
2. POST `/orders` com `quote_id` → retorna dados PIX
3. Cliente paga PIX → webhook notifica
4. Consulta `/orders/{id}` para status final

### Off-ramp (USDT → PIX)

| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/sell/quotes` | POST | Cotação de venda |
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

---

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

---

## Tipos

| Campo | Valores |
|-------|---------|
| `asset` | `USDT`, `USDC` |
| `network` | `polygon`, `ethereum`, `tron`, `solana`, `bsc`, `arbitrum` |
| `direction` | `on_ramp`, `off_ramp`, `wallet_transfer` |
| `display_status` | `awaiting_payment`, `awaiting_deposit`, `processing`, `completed`, `failed` |

---

## Taxas

| Operação | Taxa |
|----------|------|
| On-ramp (PIX → USDT) | 3% + fixa + rede |
| Off-ramp (USDT → PIX) | 1,5% + fixa + R$3,50 |

> Consultar Lexxen para taxas exatas atualizadas.

---

## Custos estimados (Clareo)

| Cenário | On-ramp (3%) | Off-ramp (1,5%+R$3,50) | Gas Polygon | Total |
|---------|-------------|------------------------|-------------|-------|
| R$100 doação | R$3,00 | — | ~R$0,50 | R$3,50 |
| R$500 resgate | — | R$11,00 | ~R$0,50 | R$11,50 |
| R$1.000 resgate | — | R$18,50 | ~R$0,50 | R$19,00 |

---

## Segurança

| Camada | Detalhe |
|--------|---------|
| Transporte | TLS 1.3 |
| Dados | Tokenização em repouso |
| Autenticação | HMAC-SHA256 com timestamp ±60s |
| Webhooks | Assinatura HMAC |
