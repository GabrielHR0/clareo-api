# Clareo — Integração NOWPayments

> Referências oficiais:
> - https://documenter.getpostman.com/view/7907941/2s93JusNJt
> - https://nowpayments.io/

## Visão Geral

NOWPayments é utilizado para:
- Widget de pagamento PIX para doadores
- Webhook de confirmação de pagamento

**Taxa:** 0.5%
**Modo:** Non-custodial (fundos vão direto para nossa wallet)

## Configuração

### Variáveis de Ambiente

```bash
# .env
NOWPAYMENTS_API_KEY=sua_api_key_aqui
NOWPAYMENTS_IPN_SECRET=seu_ipn_secret_aqui
NOWPAYMENTS_SANDBOX=true # false em produção
```

## Endpoints Utilizados

### 1. Criar Pagamento

```ruby
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

### 2. Consultar Status do Pagamento

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

## Webhook (IPN)

### Controller

```ruby
class Api::V1::WebhooksController < ApplicationController
  skip_before_action :authenticate_user!

  def nowpayments
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

## Taxas

| Tipo | Taxa |
|------|------|
| On-ramp (BRL → USDT) | 0.5% |
| Off-ramp (USDT → BRL) | 0.5% |

## Limites

| Limite | Valor |
|--------|-------|
| Pagamento mínimo | R$10 |
| Pagamento máximo | R$50.000 |

## Segurança

- Verificar sempre a assinatura IPN
- Usar sandbox para testes
- Validar todos os dados recebidos
- Nunca confiar apenas no status do webhook
