# Clareo — Integração Binance API

> Referência oficial: https://developers.binance.com/en/docs/catalog

## Visão Geral

A Binance é utilizada para:
- Consultar cotação USDT/BRL em tempo real
- Comprar USDT com BRL (quando doador paga)
- Vender USDT para BRL (quando beneficiário saca)

## Configuração

### Variáveis de Ambiente

```ruby
# .env
BINANCE_API_KEY=sua_api_key_aqui
BINANCE_API_SECRET=seu_api_secret_aqui
```

### Gem Ruby

```ruby
# Gemfile
gem 'binance-ruby' # Cliente oficial Binance
```

## Endpoints Utilizados

### 1. Cotação USDT/BRL

```ruby
# GET /api/v3/ticker/price
# Referência: https://developers.binance.com/en/docs/spot/market-data-rest-api

def get_usdt_brl_price
  uri = URI('https://api.binance.com/api/v3/ticker/price?symbol=USDTBRL')
  response = Net::HTTP.get(uri)
  data = JSON.parse(response)
  data['price'].to_f
end
```

**Resposta:**
```json
{
  "symbol": "USDTBRL",
  "price": "5.05000000"
}
```

### 2. Criar Ordem de Compra

```ruby
# POST /api/v3/order
# Referência: https://developers.binance.com/en/docs/spot/trading-rest-api

def buy_usdt(amount_brl)
  price = get_usdt_brl_price
  price_with_spread = price * 1.002 # Spread de 0.2%
  quantity = (amount_brl / price_with_spread).round(4)

  params = {
    symbol: 'USDTBRL',
    side: 'BUY',
    type: 'MARKET',
    quantity: quantity
  }

  response = signed_request('/api/v3/order', params)
  response
end
```

**Resposta:**
```json
{
  "orderId": 123456789,
  "symbol": "USDTBRL",
  "status": "FILLED",
  "type": "MARKET",
  "side": "BUY",
  "price": "5.05000000",
  "executedQty": "19.76000000",
  "cummulativeQuoteQty": "100.00000000"
}
```

### 3. Consultar Saldo

```ruby
# GET /api/v3/account
# Referência: https://developers.binance.com/en/docs/spot/account-rest-api

def get_balance(asset)
  response = signed_request('/api/v3/account')
  balances = response['balances']
  usdt = balances.find { |b| b['asset'] == asset }
  usdt['free'].to_f
end
```

## Autenticação HMAC-SHA256

```ruby
def signed_request(endpoint, params = {})
  params[:timestamp] = (Time.now.to_f * 1000).to_i
  params[:signature] = sign(params)

  uri = URI("https://api.binance.com#{endpoint}")
  uri.query = URI.encode_www_form(params)

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Get.new(uri.request_uri)
  request['X-MBX-APIKEY'] = ENV['BINANCE_API_KEY']

  response = http.request(request)
  JSON.parse(response.body)
end

def sign(params)
  query = URI.encode_www_form(params)
  OpenSSL::HMAC.hexdigest('SHA256', ENV['BINANCE_API_SECRET'], query)
end
```

## Rate Limits

- **Requisições:** 1200 por minuto
- **Ordens:** 10 por segundo / 200,000 por dia
- **Dados de mercado:** 1200 por minuto

## Taxas

| Tipo | Taxa |
|------|------|
| Maker | 0.1% |
| Taker | 0.1% |
| Desconto BNB | 25% off (0.075%) |

## Segurança

- **NUNCA** exponha API keys no código
- Use variáveis de ambiente
- Restrinja permissões da API key (apenas trade)
- Habilite whitelist de IPs se possível
- Monitore uso da API no painel Binance
