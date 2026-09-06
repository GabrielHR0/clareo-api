# Clareo — Integração Aave V3 (Yield)

> Referências oficiais:
> - https://docs.aave.com/
> - https://aave.com/

## Visão Geral

Aave V3 é utilizado para:
- Depositar USDT e gerar yield (3-5% APY)
- Sacar USDT quando beneficiário solicita saque
- Monitorar posições e rendimento

**Por que Aave e não JustLend:**
- APY: Aave 3-5% vs JustLend 1.35%
- TVL: $38.6B (maior protocolo DeFi)
- Multi-chain: 15+ blockchains
- Battle-tested: funciona desde 2020

## Contratos Inteligentes

```ruby
# config/aave.rb
AAVE_POOL_ADDRESS = '0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2' # Ethereum
AAVE_POOL_ADDRESS_POLYGON = '0x794a61358D6845594F94dc1DB02A252b5b4814aD'
USDT_ADDRESS = '0xdAC17F958D2ee523a2206206994597C13D831ec7' # Ethereum
USDT_ADDRESS_POLYGON = '0xc2132D05D31c914a87C6611C10748AEb04B58e8F'
```

## Operações

### 1. Consultar APY Atual

```javascript
app.get('/aave/apy', async (req, res) => {
  const pool = await ethers.getContractAt(AAVE_POOL_ABI, AAVE_POOL_ADDRESS);
  const reserves = await pool.getReserveData(USDT_ADDRESS);
  
  const supplyRate = reserves.currentLiquidityRate;
  const apy = (supplyRate / 1e27) * 100;
  
  res.json({ apy: apy.toFixed(2) });
});
```

### 2. Depositar USDT (Supply)

```javascript
app.post('/aave/supply', async (req, res) => {
  const { amount, privateKey } = req.body;
  
  // Aprovar USDT para o Aave
  const usdt = new ethers.Contract(USDT_ADDRESS, ERC20_ABI, wallet);
  await usdt.approve(AAVE_POOL_ADDRESS, ethers.parseUnits(amount, 6));
  
  // Depositar no Aave
  const pool = new ethers.Contract(AAVE_POOL_ADDRESS, AAVE_POOL_ABI, wallet);
  const tx = await pool.supply(USDT_ADDRESS, ethers.parseUnits(amount, 6), wallet.address, 0);
  
  res.json({ txHash: tx.hash });
});
```

### 3. Sacar USDT (Withdraw)

```javascript
app.post('/aave/withdraw', async (req, res) => {
  const { amount, privateKey } = req.body;
  
  const pool = new ethers.Contract(AAVE_POOL_ADDRESS, AAVE_POOL_ABI, wallet);
  const tx = await pool.withdraw(USDT_ADDRESS, ethers.parseUnits(amount, 6), wallet.address);
  
  res.json({ txHash: tx.hash });
});
```

### 4. Consultar Saldo

```javascript
app.get('/aave/balance/:address', async (req, res) => {
  const pool = new ethers.Contract(AAVE_POOL_ADDRESS, AAVE_POOL_ABI, wallet);
  const balance = await pool.getReserveData(USDT_ADDRESS);
  
  // aToken balance (yield-bearing)
  const aToken = new ethers.Contract(USDT_ADDRESS, ERC20_ABI, wallet);
  const aBalance = await aToken.balanceOf(req.params.address);
  
  res.json({
    aBalance: ethers.formatUnits(aBalance, 6),
    underlyingBalance: ethers.formatUnits(balance.liquidity, 6)
  });
});
```

## Gas Estimation

```ruby
def estimate_gas(action)
  case action
  when :supply
    200_000
  when :withdraw
    250_000
  when :approve
    60_000
  end
end
```

## Yield Monitor Job

```ruby
class YieldMonitorJob < ApplicationJob
  queue_as :default

  def perform
    Wallet.active.each do |wallet|
      balance = AaveService.get_balance(wallet.address)
      apy = AaveService.get_apy

      YieldSnapshot.create!(
        wallet: wallet,
        balance: balance,
        apy: apy,
        earned: calculate_earned(wallet, balance),
        protocol: 'aave'
      )
    end
  end
end
```

## Riscos

- Smart contract risk (audited, mas não zero)
- Liquidity risk (baixo para USDT)
- Oracle risk (preços podem divergir temporariamente)
- **Mitigação:** Diversificar entre Aave e Morpho

## Referências

- Aave V3 Docs: https://docs.aave.com/
- Aave App: https://app.aave.com/
- Contrato Pool Ethereum: https://etherscan.io/address/0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2
