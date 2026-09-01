# Clareo — Integração NOWPayments

> Referências oficiais:
> - https://documenter.getpostman.com/view/7907941/2s93JusNJt
> - https://nowpayments.io/blog/integration-guide

## Visão Geral

NOWPayments é utilizado para:
- On-ramp: Converter BRL (via PIX) para USDT
- Off-ramp: Converter USDT para BRL (PIX para beneficiários)
- Aceitar múltiplos métodos de pagamento

## Configuração

### Variáveis de Ambiente

```bash
# .env
NOWPAYMENTS_API_KEY=sua_api_key_aqui
NOWPAYMENTS_IPN_SECRET=seu_ipn_secret_aqui
NOWPAYMENTS_SANDBOX=true # false em produção
```

### Gem Ruby

```ruby
# Gemfile
gem 'httparty' # Para chamadas HTTP
```

## API Endpoints

### 1. Criar Pagamento (Create Payment)

```ruby
# Referência: https://documenter.getpostman.com/view/7907941/2s93JusNJt#9a4b8b3b-5c4e-4f8a-9b0a-3e2d1c0b5f6a

def create_payment(amount_brl, order_id)
  response = HTTParty.post(
    'https://api.nowpayments.io/v1/payment',
    headers: {
      'x-api-key' => ENV['NOWPAYMENTS_API_KEY'],
      'Content-Type' => 'application/json'
    },
    body: {
      price_amount: amount_brl,
      price_currency: 'brl',
      pay_currency: 'usdttrc20',
      order_id: order_id,
      order_description: "Doação ##{order_id}",
      ipn_callback_url: "#{ENV['APP_URL']}/api/v1/webhooks/nowpayments"
    }.to_json
  )

  JSON.parse(response.body)
end
```

**Resposta:**
```json
{
  "id": 12345,
  "order_id": "donation_abc123",
  "payment_status": "waiting",
  "pay_address": "T...",
  "price_amount": 100.00,
  "price_currency": "brl",
  "amount": 19.76,
  "amount_currency": "usdttrc20",
  "payment_url": "https://nowpayments.io/payment?invoice_id=..."
}
```

### 2. Criar Withdrawal (Off-ramp)

```ruby
# Referência: https://documenter.getpostman.com/view/7907941/2s93JusNJt#withdrawal

def create_withdrawal(amount_usdt, pix_key)
  response = HTTParty.post(
    'https://api.nowpayments.io/v1/withdrawal',
    headers: {
      'x-api-key' => ENV['NOWPAYMENTS_API_KEY'],
      'Content-Type' => 'application/json'
    },
    body: {
      withdrawals: [{
        currency: 'usdttrc20',
        amount: amount_usdt,
        withdrawal_address: pix_key,
        payout_method: 'pix'
      }]
    }.to_json
  )

  JSON.parse(response.body)
end
```

### 3. Consultar Status do Pagamento

```ruby
def get_payment_status(payment_id)
  response = HTTParty.get(
    "https://api.nowpayments.io/v1/payment/#{payment_id}",
    headers: {
      'x-api-key' => ENV['NOWPAYMENTS_API_KEY']
    }
  )

  JSON.parse(response.body)
end
```

## Webhook (IPN - Instant Payment Notification)

### Configuração

```ruby
# routes.rb
Rails.application.routes.draw do
  post '/api/v1/webhooks/nowpayments', to: 'webhooks#nowpayments'
end
```

### Controller

```ruby
# app/controllers/api/v1/webhooks_controller.rb
class Api::V1::WebhooksController < ApplicationController
  skip_before_action :authenticate_user!

  def nowpayments
    # Verificar assinatura IPN
    unless verify_ipn_signature(request.headers['x-nowpayments-sig'])
      render json: { error: 'Invalid signature' }, status: :unauthorized
      return
    end

    payload = JSON.parse(request.body.read)

    case payload['payment_status']
    when 'finished'
      DonationService.confirm!(payload['order_id'])
    when 'failed'
      DonationService.mark_failed!(payload['order_id'])
    end

    render json: { status: 'ok' }
  end

  private

  def verify_ipn_signature(signature)
    expected = OpenSSL::HMAC.hexdigest(
      'SHA512',
      ENV['NOWPAYMENTS_IPN_SECRET'],
      request.body.string
    )
    ActiveSupport::SecurityUtils.secure_compare(signature, expected)
  end
end
```

## Métodos de Pagamento Suportados

| Método | País | Status |
|--------|------|--------|
| PIX | Brasil | ✅ |
| Boleto | Brasil | ✅ |
| Cartão de crédito | Global | ✅ |
| Transferência bancária | Global | ✅ |

## Taxas NOWPayments

| Tipo | Taxa |
|------|------|
| On-ramp (BRL → USDT) | 1-2% |
| Off-ramp (USDT → BRL) | 1-2% |
| API Fee | 0.5% |

## Limites

| Limite | Valor |
|--------|-------|
| Pagamento mínimo | R$10 |
| Pagamento máximo | R$50.000 |
| Withdrawal mínimo | $10 USDT |
| Withdrawal máximo | $10.000 USDT |

## Segurança

- Verificar sempre a assinatura IPN
- Usar sandbox para testes
- Validar todos os dados recebidos
- Nunca confiar apenas no status do webhook (verificar via API)
