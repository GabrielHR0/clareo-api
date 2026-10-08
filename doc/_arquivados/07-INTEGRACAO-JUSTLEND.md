# Clareo — Integração JustLend

> Referências oficiais:
> - https://docs.justlend.org/
> - https://docs.justlend.org/developers/apis/
> - https://developers.tron.network/docs/justlend-api

## Visão Geral

JustLend é utilizado para:
- Depositar USDT e gerar yield (~1.35% APY)
- Sacar USDT quando beneficiário solicita saque
- Monitorar posições e rendimento

## Contratos Inteligentes

```ruby
# config/justlend.rb
JUSTLEND_COMPTROLLER = 'TX7QNd8Vr7VgqgvXkEBK5RBX6jTJFm5vA'
JUSTLEND_USDT_CTOKEN = 'TBDZs8sHXY8dBX9rYJbE9U8V2Hm4q5J2w' # cUSDT
USDT_ADDRESS = 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t'
```

## Operações

### 1. Consultar APY Atual

```javascript
// GET /justlend/apy
app.get('/justlend/apy', async (req, res) => {
  const contract = await tronWeb.contract().at(JUSTLEND_COMPTROLLER);
  const markets = await contract.methods.markets(USDT_ADDRESS).call();

  // APY = supplyRate / 1e18 * (365 * 24 * 60 * 60) * 100
  const supplyRate = markets.supplyRateMantissa.toString();
  const apy = (supplyRate / 1e18) * 365 * 24 * 60 * 60 * 100;

  res.json({ apy: apy.toFixed(2) });
});
```

### 2. Depositar USDT (Supply)

```javascript
// POST /justlend/supply
app.post('/justlend/supply', async (req, res) => {
  const { amount, privateKey } = req.body;

  tronWeb.setPrivateKey(privateKey);
  const cToken = await tronWeb.contract().at(JUSTLEND_USDT_CTOKEN);

  // Aprovar USDT para o JustLend
  const usdt = await tronWeb.contract().at(USDT_ADDRESS);
  await usdt.approve(JUSTLEND_USDT_CTOKEN, tronWeb.toSun(amount)).send();

  // Depositar USDT
  const result = await cToken.mint(tronWeb.toSun(amount)).send();

  res.json({ txHash: result });
});
```

### 3. Sacar USDT (Redeem)

```javascript
// POST /justlend/redeem
app.post('/justlend/redeem', async (req, res) => {
  const { amount, privateKey } = req.body;

  tronWeb.setPrivateKey(privateKey);
  const cToken = await tronWeb.contract().at(JUSTLEND_USDT_CTOKEN);

  // Sacar USDT (amount em USDT, não em cTokens)
  const result = await cToken.redeemUnderlying(tronWeb.toSun(amount)).send();

  res.json({ txHash: result });
});
```

### 4. Consultar Saldo em cTokens

```javascript
// GET /justlend/balance/:address
app.get('/justlend/balance/:address', async (req, res) => {
  const cToken = await tronWeb.contract().at(JUSTLEND_USDT_CTOKEN);
  const balance = await cToken.balanceOf(req.params.address).call();

  // Converter cTokens para USDT
  const exchangeRate = await cToken.exchangeRateCurrent().call();
  const usdtBalance = (balance.toString() * exchangeRate.toString()) / 1e18;

  res.json({
    cTokens: balance.toString(),
    usdtBalance: usdtBalance.toFixed(6)
  });
});
```

## Risk Management

- JustLend utiliza **clean liquidation**
- Taxa de colateralização: 75%
- Se valor dívida > 75% do colateral, posição é liquidada
- Para o nosso caso (yield apenas), risco é mínimo pois não fazemos borrowing

## Gas Estimation

```ruby
def estimate_gas(action, params)
  # Aproximado para JustLend
  case action
  when :supply
    200_000 # ~0.2 TRX
  when :redeem
    250_000 # ~0.25 TRX
  when :approve
    60_000  # ~0.06 TRX
  end
end
```

## Monitoramento

```ruby
# Job Sidekiq para monitorar yield
class YieldMonitorJob < ApplicationJob
  queue_as :default

  def perform
    wallets = Wallet.active.where.not(justlend_balance: nil)

    wallets.each do |wallet|
      balance = JustLendService.get_balance(wallet.address)
      apy = JustLendService.get_apy

      YieldSnapshot.create!(
        wallet: wallet,
        balance: balance,
        apy: apy,
        earned: calculate_earned(wallet, balance)
      )
    end
  end
end
```

## Referências

- JustLend Docs: https://docs.justlend.org/
- JustLend API: https://docs.justlend.org/developers/apis/
- Contrato Comptroller: https://tronscan.org/#/contract/TX7QNd8Vr7VgqgvXkEBK5RBX6jTJFm5vA
- Contrato cUSDT: https://tronscan.org/#/contract/TBDZs8sHXY8dBX9rYJbE9U8V2Hm4q5J2w
