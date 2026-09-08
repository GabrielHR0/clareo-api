# Lexxen API — Referência Completa

## Visão Geral

| Item | Detalhe |
|------|---------|
| Empresa | LEXXEN LTDA |
| CNPJ | 63.987.111/0001-53 |
| Sede | Rua 15, nº 721 — Setor Marista, Goiânia/GO · CEP 74.150-020 |
| Contato | support@lexxen.com · WhatsApp: +55 800-000-4531 |
| Papa | Crypto-as-a-service (serviços financeiros via instituições parceiras autorizadas) |
| Regulação | Licença crypto-as-a-service; KYC/AML/PLD-FT; instituições parceiras reguladas |
| Clientes | 3.000+ ativos |
| Volume | R$ 270M+ movimentados em 2025; R$ 3,2M em PIX/dia (média) |
| Uptime | 99,9% |

> **Nota legal:** A Lexxen é provedora de tecnologia. Os serviços financeiros e de ativos virtuais são prestados por instituições parceiras autorizadas por seus respectivos reguladores. A Lexxen não é instituição financeira, instituição de pagamento, emissora de cartões nem prestadora de serviços de ativos virtuais.

---

## Links Oficiais

| Recurso | Link |
|---------|------|
| Site | https://www.lexxen.com |
| App (login) | https://app.lexxen.com |
| API Docs (Hub) | https://cashout.lexxen.com/docs |
| API Docs (LLM) | https://cashout.lexxen.com/docs/llms.md |
| Postman Collection | https://cashout.lexxen.com/postman/Lexxen_Hub_API.postman_collection.json |
| Sandbox | https://cashout.lexxen.com (chave `lxn_test_...`) |
| Conta (registro) | https://www.lexxen.com/register |
| WhatsApp | https://wa.me/558000004531 |
| Suporte | support@lexxen.com |

### Links Legais

| Documento | Link |
|-----------|------|
| Termos de Uso | https://www.lexxen.com/terms |
| Política de Privacidade | https://www.lexxen.com/privacy |
| Política de Cookies | https://www.lexxen.com/cookies |
| Riscos de Criptoativos | https://www.lexxen.com/crypto-risks |
| Código de Ética | https://www.lexxen.com/code-of-conduct |
| Canal de Denúncias | https://www.lexxen.com/whistleblower |
| Segurança | https://www.lexxen.com/security |

### Produtos Lexxen

| Produto | Link | Descrição |
|---------|------|-----------|
| Mesa OTC | https://www.lexxen.com/products/otc-desk | Câmbio BRL ↔ cripto, +80 moedas, 24/7 |
| Virtual Accounts | https://www.lexxen.com/products/virtual-accounts | Receba via Wire, SEPA, SPEI em dólar digital |
| Cartões Nacionais | https://www.lexxen.com/products/national-cards | Cartões virtuais em BRL |
| Cartões Cripto | https://www.lexxen.com/products/crypto-cards | Saldo em cripto, sem IOF, Apple/Google Pay |
| API Cripto | https://www.lexxen.com/products/crypto-api | On/off-ramp USDT com PIX (o que usamos) |
| Conta Digital | https://www.lexxen.com/products/digital-account | PF e PJ, PIX, TED, boleto |

### Empresa

| Link | Descrição |
|------|-----------|
| https://www.lexxen.com/about | Sobre a Lexxen |
| https://www.lexxen.com/blog | Blog |
| https://www.lexxen.com/contact | Contato |
| Instagram | https://www.instagram.com/lexxen.oficial/ |
| LinkedIn | https://www.linkedin.com/company/lexxenoficial/ |
| TikTok | https://www.tiktok.com/@lexxen.oficial |

---

## Produtos Disponíveis

### 1. API Cripto (Nosso caso de uso)

On/off-ramp USDT com PIX, wallets multi-rede e webhooks assinados.

**Recursos:**
- On-ramp: PIX → USDT/USDC em segundos
- Off-ramp: Cripto → PIX
- Gestão de wallets com saldo em tempo real
- Multi-rede: Polygon, Ethereum, Tron, Solana (também BSC e Arbitrum)
- Webhooks de eventos de transação (HMAC assinado)
- Autenticação HMAC-SHA256
- Liquidação local (PIX) + stablecoin global
- Sandbox gratuito com dados sintéticos

### 2. Mesa OTC

Câmbio BRL ↔ cripto com alta liquidez, 24/7.

**Recursos:**
- Plugados em mesa OTC tier-1 da América Latina
- Liquidez 24h/7 dias
- +80 criptomoedas com par direto em BRL
- Multi-chain: Ethereum, Solana, Tron, BSC, Polygon, Arbitrum
- Spread por volume (~0,38% em USDT/BRL)
- Liquidação em segundos via PIX
- Cotação e spread visíveis antes de executar
- Auditoria completa (CSV, JSON)
- Condições dedicadas para PJ e traders de alta frequência

### 3. Conta Digital

PF e PJ, PIX ilimitado, TED, boleto.

**Recursos:**
- Abertura 100% digital, aprovação em até 24h
- PIX ilimitado 24h (QR Code, chave aleatória, conciliação automática)
- Sem limites artificiais
- Extrato e movimentação

### 4. Cartões Nacionais

Virtuais em BRL para pagamentos.

**Recursos:**
- Limite independente por cartão
- Bloqueio/desbloqueio em 1 clique
- Aceito em Meta Ads, Google Ads, TikTok Ads
- Recarga via PIX ou saldo
- Histórico detalhado por cartão

### 5. Cartões Cripto

Saldo em cripto, sem IOF.

**Recursos:**
- Apple Pay e Google Pay
- Zero IOF em compras internacionais
- Cartões virtuais e físicos
- BIN e branding customizáveis (White-Label)

### 6. Virtual Accounts

Receba pagamentos internacionais.

**Recursos:**
- Wire, SEPA, SPEI
- Dólar digital

### 7. BaaS (White-Label)

Infraestrutura bancária completa via API REST.

**Recursos:**
- Contas PJ embutidas (onboarding, KYC, compliance)
- PIX programático (QR Codes, webhooks, conciliação)
- Cartões on-demand (BIN próprio, branding customizável)
- Sub-contas ilimitadas (hierarquias, limites, permissões)
- Webhooks em tempo real (transação, KYC, saldo)
- Sandbox completo (espelho da produção)
- SDKs: Node, Python, Go
- Documentação OpenAPI 3.0
- Rate limit generoso
- Suporte técnico via Slack

### Planos

| Plano | Descrição |
|-------|-----------|
| API Pública | Sandbox gratuito, docs OpenAPI 3.0, SDKs, webhooks, rate limit generoso, suporte via Slack |
| Enterprise White-Label | BIN e bandeira próprios, painel customizável, KYC em sua marca, SLA 99,95%, CS dedicado, setup em 60 dias |

---

## Taxas

### API Cripto

| Operação | Taxa | Detalhes |
|----------|------|----------|
| On-ramp (PIX → USDT) | 3% + fixa + rede | Cotação ~5 min; liquidado em segundos |
| Off-ramp (USDT → PIX) | 1,5% + fixa + R$3,50 | Liquidação via PIX |

### Mesa OTC

| Indicador | Valor |
|-----------|-------|
| Spread médio USDT/BRL | ~0,38% |
| Spread por volume | Melhora conforme volume cresce |
| Liquidação | Em segundos (PIX) ou minutos (on-chain) |
| IOF | Sem surpresa de IOF |

### Conta Digital

| Serviço | Taxa |
|---------|------|
| Abertura de conta | Grátis |
| PIX | Sem limites artificiais |
| Mensalidade | Não especificada (contatar) |

### Cartões

| Serviço | Taxa |
|---------||
| Emissão virtual | Não especificada |
| IOF compras internacionais | 0% (cartão cripto) |

> **Nota:** Taxas exatas para API podem variar. Consultar Lexxen para condições atualizadas.

---

## API — Base URL e Autenticação

### Base URL

```
https://cashout.lexxen.com/api/v1
```

### Autenticação (HMAC-SHA256)

Todos os endpoints usam HMAC-SHA256.

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

## API — Endpoints

### On-ramp (PIX → USDT)

| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/quotes` | POST | Cria cotação (trava preço ~5 min) |
| `/orders` | POST | Cria pedido (gera PIX para pagamento) |
| `/orders/{id}` | GET | Consulta status do pedido |

**Fluxo:**
1. POST `/quotes` → retorna `quote_id` e valor USDT
2. POST `/orders` com `quote_id` → retorna dados PIX (QR Code, payload)
3. Cliente paga PIX → webhook notifica pagamento
4. Consulta `/orders/{id}` para status final

### Off-ramp (USDT → PIX)

| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/sell/quotes` | POST | Cotação de venda (cripto → BRL) |
| `/sell/orders` | POST | Cria pedido de venda |
| `/sell/orders/{id}` | GET | Consulta status |

### Wallets

| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/wallets` | GET | Lista carteiras do tenant |
| `/wallets/validate` | POST | Valida endereço de carteira |

### Saldo

| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/balance` | GET | Saldo unificado (PIX + cripto) |
| `/balance/banking` | GET | Saldo no banking core |

---

## API — Webhooks

### Eventos

| Evento | Descrição |
|--------|-----------|
| `transaction.completed` | Operação concluída com sucesso |
| `transaction.failed` | Falha na operação |

### Payload exemplo

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

## API — Tipos

| Campo | Valores |
|-------|---------|
| `asset` | `USDT`, `USDC` |
| `network` | `polygon`, `ethereum`, `tron`, `solana`, `bsc`, `arbitrum` |
| `direction` | `on_ramp`, `off_ramp`, `wallet_transfer` |
| `display_status` | `awaiting_payment`, `awaiting_deposit`, `processing`, `completed`, `failed` |

---

## Segurança

| Camada | Detalhe |
|--------|---------|
| Transporte | TLS 1.3 em todas as rotas |
| Dados | Tokenização de dados sensíveis em repouso |
| Autenticação | HMAC-SHA256 com timestamp ±60s |
| Webhooks | Assinatura HMAC para validação |
| KYC | Biometria facial + análise documental |
| AML | Monitoramento contínuo |
| PLD-FT | Prevenção à Lavagem de Dinheiro e Financiamento ao Terrorismo |
| Auditoria | Internas e externas contínuas |

---

## Integração com Clareo

### Por que Lexxen?

1. **Provider único** — Uma API faz PIX→USDT e USDT→PIX
2. **Regulado** — Licença crypto-as-a-service, compliance resolvido
3. **Sandbox gratuito** — Sem custo para desenvolvimento
4. **Multi-rede** — Polygon (custo baixo), Ethereum, Tron, Solana
5. **Webhooks** — Notificações em tempo real com HMAC
6. **SDKs** — Node, Python, Go
7. **Docs OpenAPI 3.0** — Documentação padronizada
8. **Spread competitivo** — ~0,38% USDT/BRL na mesa OTC

### Custos estimados (Clareo)

| Cenário | On-ramp (3%) | Off-ramp (1,5% + R$3,50) | Gas Polygon | Total |
|---------|-------------|-------------------------|-------------|-------|
| R$100 doação | R$3,00 | — | ~R$0,50 | R$3,50 |
| R$500 resgate | — | R$7,50 + R$3,50 | ~R$0,50 | R$11,50 |
| R$1.000 resgate | — | R$15,00 + R$3,50 | ~R$0,50 | R$19,00 |

> **Nota:** Taxas da API podem ser diferentes das listadas. Consultar Lexxen para condições exatas.

### Próximos passos

1. Criar conta Lexxen (sandbox)
2. Obter chaves API (`lxn_test_...`)
3. Testar fluxo on-ramp no sandbox
4. Testar fluxo off-ramp no sandbox
5. Implementar `LexxenService` no Clareo
