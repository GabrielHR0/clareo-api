# Clareo — Roadmap de Implementação (MVP)

## Estratégia

Focar no essencial: receber doação e permitir resgate.
Validar fluxo completo de caixa antes de adicionar features.

```
MVP                    FUTURO
Receber + Resgatar  →  Yield + Multi-chain + Dashboard
(4 semanas)            (após validação)
```

---

## MVP: Receber + Resgatar (4 semanas)

### Objetivo
Doador paga PIX → USDT na wallet → Instituição resgata via PIX

### Custo por doação: ~2.04%
### Custo por saque: ~0.60%

---

### Semana 1: Setup + Auth

#### Setup (2 dias)
- [ ] Configurar Kino (remover Puma)
- [ ] Configurar PostgreSQL
- [ ] Configurar Redis + Sidekiq
- [ ] Setup Docker Compose
- [ ] Configurar RSpec

#### Models e Database (2 dias)
- [ ] Migration: users
- [ ] Migration: wallets
- [ ] Migration: donations
- [ ] Migration: withdrawals
- [ ] Configurar associações + validações + indexes

#### Autenticação (1 dia)
- [ ] JWT encode/decode
- [ ] AuthController (login/register/me)
- [ ] Middleware de autenticação
- [ ] Rate limiting

---

### Semana 2: Services

#### Exchange Interface (1 dia)
- [ ] Criar ExchangeInterface
- [ ] BinanceService (get_price, buy_usdt, sell_usdt)

#### Blockchain Interface (1 dia)
- [ ] Criar BlockchainInterface
- [ ] TronService (create_wallet, get_balance, transfer_usdt)

#### Payment Interface (1 dia)
- [ ] Criar PaymentInterface
- [ ] NowPaymentsService (create_payment, send_pix)

#### Donation + Withdrawal Services (2 dias)
- [ ] DonationService (create, confirm)
- [ ] WithdrawalService (process)

---

### Semana 3: Controllers + Fluxo

#### API Controllers (2 dias)
- [ ] DonationsController (create, show, index)
- [ ] WalletsController (create, index)
- [ ] WithdrawalsController (create, show, index)
- [ ] AuthController (login, register, me)

#### Webhooks (1 dia)
- [ ] WebhooksController (NOWPayments IPN)
- [ ] Verificação de assinatura

#### Jobs (1 dia)
- [ ] DonationConfirmJob
- [ ] WithdrawalProcessJob

#### Testes (1 dia)
- [ ] Testes de model
- [ ] Testes de service (mock)
- [ ] Testes de controller

---

### Semana 4: Teste + Deploy

#### Teste End-to-End (2 dias)
- [ ] Teste com sandbox Binance
- [ ] Teste com sandbox NOWPayments
- [ ] Teste completo do fluxo

#### Deploy (2 dias)
- [ ] Dockerfile + docker-compose.yml
- [ ] Variáveis de ambiente
- [ ] Health check
- [ ] Deploy staging
- [ ] Deploy produção

---

## FUTURO (após validação do MVP)

| Item | Prioridade | Quando |
|------|------------|--------|
| Yield (Aave V3) | Alta | Após validação |
| Solana | Média | Após yield |
| Dashboard admin | Média | Após stable |
| Notificações push | Baixa | Após stable |
| App mobile | Baixa | Após scale |
| Multi-idioma | Baixa | Após scale |

---

## Marcos

| Marco | Entregável | Quando |
|-------|------------|--------|
| **MVP Funcional** | Doação + Saque completo | Semana 4 |
| **Beta** | Testes completos | Semana 4 |
| **Produção** | Deploy final | Semana 4 |

---

## Timeline

| Fase | Dias | Dependências |
|------|------|--------------|
| **MVP** | 20-25 | - |
| **Yield** | 15-20 | MVP validado |
| **Multi-chain** | 10-15 | Yield validado |

---

## Prioridades Pós-MVP

1. Yield (Aave V3)
2. Multi-chain (Solana)
3. Dashboard admin
4. Notificações push
5. App mobile (React Native)
