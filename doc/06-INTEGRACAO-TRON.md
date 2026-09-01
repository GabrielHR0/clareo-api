# Clareo — Integração TRON

> Referências oficiais:
> - https://developers.tron.network/
> - https://developers.tron.network/docs/tronweb-1

## Visão Geral

TRON é utilizada para:
- Criar carteiras para armazenar USDT TRC-20
- Enviar/receber USDT entre carteiras
- Staking de TRX para transações gratuitas
- Monitorar status de transações

## Configuração do TronWeb

### Node.js Sidecar

Como TronWeb é uma biblioteca JavaScript, utilizamos um sidecar Node.js:

```bash
# node_sidecar/package.json
{
  "name": "clareo-tron-sidecar",
  "version": "1.0.0",
  "dependencies": {
    "tronweb": "^5.3.0",
    "express": "^4.18.2"
  }
}
```

### Variáveis de Ambiente

```bash
# .env
TRON_FULL_HOST=https://api.trongrid.io
TRON_API_KEY=sua_api_key_aqui
TRON_MASTER_WALLET_ADDRESS=TSEHe6DwQUMfBkqXJsRCNFyU8d9p2qaxBZ
TRON_MASTER_PRIVATE_KEY=chave_privada_criptografada
```

## Endpoints do Sidecar

### 1. Criar Carteira

```javascript
// POST /wallet/create
app.post('/wallet/create', async (req, res) => {
  const account = await tronWeb.createAccount();
  res.json({
    address: account.address.base58,
    privateKey: account.privateKey
  });
});
```

### 2. Consultar Saldo USDT

```javascript
// GET /wallet/:address/balance
app.get('/wallet/:address/balance', async (req, res) => {
  const contract = await tronWeb.contract().at(USDT_CONTRACT_ADDRESS);
  const balance = await contract.methods.balanceOf(req.params.address).call();
  res.json({ balance: balance.toString() });
});
```

### 3. Enviar USDT

```javascript
// POST /wallet/transfer
app.post('/wallet/transfer', async (req, res) => {
  const { from, to, amount, privateKey } = req.body;

  tronWeb.setPrivateKey(privateKey);
  const contract = await tronWeb.contract().at(USDT_CONTRACT_ADDRESS);

  const result = await contract.methods.transfer(
    to,
    tronWeb.toSun(amount) // Converter para 6 casas decimais
  ).send();

  res.json({ txHash: result });
});
```

### 4. Verificar Status da Transação

```javascript
// GET /transaction/:txHash
app.get('/transaction/:txHash', async (req, res) => {
  const tx = await tronWeb.trx.getTransaction(req.params.txHash);
  res.json({
    confirmed: tx.block_number > 0,
    blockNumber: tx.block_number,
    status: tx.ret[0].contractRet
  });
});
```

## Endereço do Contrato USDT TRC-20

```ruby
# config/blockchain.rb
USDT_CONTRACT_ADDRESS = 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t'
```

## Staking de TRX

Staking de TRX garante:
- Transações gratuitas (energy + bandwidth)
- Prioridade na rede

```ruby
# Calcula TRX necessário para stake
def calculate_trx_stake
  # Mínimo recomendado: 5,000 TRX (~$0.03 cada)
  # Para transações gratuitas: 20,000 TRX
  {
    minimum: 5_000,
    recommended: 20_000,
    cost_usd: 20_000 * 0.03 # ~$600
  }
end
```

## Confirmações Necessárias

| Tipo de Transação | Confirmações |
|-------------------|--------------|
| USDT TRC-20 | 19+ |
| TRX | 19+ |
| Smart Contract | 19+ |

## Taxas na TRON

| Ação | Custo |
|------|-------|
| Transferir TRX | ~0.5 TRX (grátis com stake) |
| Transferir USDT TRC-20 | ~15 TRX (~$0.45 sem stake) |
| Deploy de Smart Contract | ~100 TRX |

## Referências

- TronWeb: https://developers.tron.network/docs/tronweb-1
- TRON HTTP API: https://developers.tron.network/reference
- Contrato USDT: https://tronscan.org/#/contract/TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t
