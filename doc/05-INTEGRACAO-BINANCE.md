# Clareo — Integração Binance API

> Referência oficial: https://developers.binance.com/

## Visão Geral

Binance é utilizada para:
- Consultar cotação USDT/BRL em tempo real
- Comprar USDT com BRL (quando doador paga)
- Vender USDT para BRL (quando beneficiário saca)

**Taxa:** 0.1% (0.075% com BNB)

## Configuração

### Variáveis de Ambiente

```ruby
# .env
BINANCE_API_KEY=sua_api_key_aqui
BINANCE_API_SECRET=seu_api_secret_aqui
```

## Endpoints Utilizados

### 1. Cotação USDT/BRL

```ruby
def get_usdt_brl_price
  uri = URI('https://api.binance.com/api/v3/ticker/price?symbol=USDTBRL')
  response = Net::HTTP.get(uri)
  data = JSON.parse(response)
  data['price'].to_f
end
```

### 2. Criar Ordem de Compra

```ruby
def buy_usdt(amount_brl)
  price = get_usdt_brl_price
  price_with_spread = price * 1.002
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

### 3. Criar Ordem de Venda

```ruby
def sell_usdt(amount_usdt)
  price = get_usdt_brl_price
  price_with_spread = price * 0.998

  params = {
    symbol: 'USDTBRL',
    side: 'SELL',
    type: 'MARKET',
    quantity: amount_usdt
  }

  response = signed_request('/api/v3/order', params)
  response
end
```

### 4. Consultar Saldo

```ruby
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

## Fallback: Mercado Bitcoin

Se Binance não funcionar, usar Mercado Bitcoin como fallback:

```ruby
class ExchangeService
  def buy_usdt(amount_brl)
    result = binance_buy(amount_brl)
    return result if result[:success]

    mercadobitcoin_buy(amount_brl)
  end
end
```

## Segurança

- Use variáveis de ambiente
- Restrinja permissões da API key (apenas trade)
- Habilite whitelist de IPs
- Monitore uso da API no painel Binance
