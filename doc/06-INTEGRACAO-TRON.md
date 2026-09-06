# Clareo — Integração TRON

> Referências oficiais:
> - https://developers.tron.network/
> - https://developers.tron.network/docs/tronweb-1

## Visão Geral

TRON é utilizada para:
- Criar carteiras para armazenar USDT TRC-20
- Enviar/receber USDT entre carteiras
- Rede primária para transações (52% do volume de stablecoins)

**Fee padrão:** ~$1.44 por transferência
**Fee com energy rental:** ~$0.20-1.44

## Configuração do TronWeb

### Node.js Sidecar

```json
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
TRON_SIDECAR_URL=http://localhost:3001
```

## Endpoints do Sidecar

### 1. Criar Carteira

```javascript
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
app.get('/wallet/:address/balance', async (req, res) => {
  const contract = await tronWeb.contract().at(USDT_CONTRACT_ADDRESS);
  const balance = await contract.methods.balanceOf(req.params.address).call();
  res.json({ balance: balance.toString() });
});
```

### 3. Enviar USDT

```javascript
app.post('/wallet/transfer', async (req, res) => {
  const { from, to, amount, privateKey } = req.body;

  tronWeb.setPrivateKey(privateKey);
  const contract = await tronWeb.contract().at(USDT_CONTRACT_ADDRESS);

  const result = await contract.methods.transfer(
    to,
    tronWeb.toSun(amount)
  ).send();

  res.json({ txHash: result });
});
```

### 4. Verificar Status da Transação

```javascript
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
USDT_CONTRACT_ADDRESS = 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t'
```

## Energy Rental (Reduzir Fees)

Serviços como TronSave permitem alugar energy:
- **65k energy:** ~4 TRX (~$0.50)
- **130k energy:** ~8 TRX (~$1.00)
- **Redução:** De ~$1.44 para ~$0.20-0.50

## Confirmações Necessárias

| Tipo de Transação | Confirmações |
|-------------------|--------------|
| USDT TRC-20 | 19+ |
| TRX | 19+ |

## Taxas na TRON

| Ação | Custo |
|------|-------|
| Transferir USDT TRC-20 | ~15 TRX (~$1.44 sem stake) |
| Transferir USDT (com energy rental) | ~3-4 TRX (~$0.30-0.40) |
