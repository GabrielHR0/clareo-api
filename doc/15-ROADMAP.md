# Clareo — Roadmap de Implementação

## Estratégia

Construir em etapas, validar cada fluxo antes de avançar.
Máxima economia por transação.

```
ETAPA 1          ETAPA 2           ETAPA 3          ETAPA 4
Validar Doação → Adicionar Saque → Yield + Multi-chain → Escalar
(15-20 dias)     (10-15 dias)      (15-20 dias)      (contínuo)
```

---

## ETAPA 1: Validar Doação (15-20 dias)

### Objetivo
Doador paga PIX → USDT chega na wallet → Pode confirmar receipt

### Custo por doação: ~2.04%

### Tasks

#### Setup (2 dias)
- [ ] Configurar Puma (não Kino)
- [ ] Configurar PostgreSQL
- [ ] Configurar Redis
- [ ] Configurar Sidekiq
- [ ] Setup Docker Compose

#### Models e Database (2 dias)
- [ ] Migration: users
- [ ] Migration: wallets
- [ ] Migration: donations
- [ ] Configurar associações
- [ ] Configurar validações
- [ ] Configurar indexes

#### Autenticação (2 dias)
- [ ] Gem JWT + bcrypt
- [ ] AuthService.encode/decode
- [ ] AuthController (login/register)
- [ ] Middleware de autenticação
- [ ] Rate limiting

#### Binance Integration (2-3 dias)
- [ ] Configurar API keys
- [ ] BinanceService: get_usdt_brl_price
- [ ] BinanceService: buy_usdt
- [ ] BinanceService: get_balance
- [ ] Testes de integração

#### TRON Integration (2-3 dias)
- [ ] Setup Node.js sidecar
- [ ] TronService: create_wallet
- [ ] TronService: get_balance
- [ ] TronService: transfer_usdt
- [ ] Testes de integração

#### NOWPayments Integration (2 dias)
- [ ] Configurar API keys
- [ ] NowPaymentsService: create_payment
- [ ] WebhooksController (IPN)
- [ ] Verificação de assinatura
- [ ] Testes de integração

#### API REST (2-3 dias)
- [ ] DonationsController (create, show, index)
- [ [ ] WalletsController (create, index)
- [ ] AuthController (login, register, me)
- [ ] Serializers/Validators

#### Jobs (1 dia)
- [ ] DonationConfirmJob
- [ ] WebhookProcessJob
- [ ] Configurar filas

#### Testes (2-3 dias)
- [ ] Configurar RSpec
- [ ] Testes de model
- [ ] Testes de service
- [ ] Testes de controller
- [ ] Testes de integração

#### Deploy (1 dia)
- [ ] Dockerfile
- [ ] docker-compose.yml
- [ ] Variáveis de ambiente
- [ ] Health check

---

## ETAPA 2: Adicionar Saque (10-15 dias)

### Objetivo
Beneficiário solicita saque → USDT vira BRL → PIX na conta

### Custo por saque: ~0.60%

### Tasks

#### Models (1 dia)
- [ ] Migration: withdrawals
- [ ] Configurar associações
- [ ] Configurar validações

#### Services (2-3 dias)
- [ ] WithdrawalService: process
- [ ] BinanceService: sell_usdt
- [ ] NowPaymentsService: create_withdrawal

#### API (2 dias)
- [ ] WithdrawalsController (create, show, index)
- [ ] Serializers/Validators

#### Jobs (1-2 dias)
- [ ] WithdrawalProcessJob
- [ ] Configurar filas

#### Testes (2-3 dias)
- [ ] Testes de model
- [ ] Testes de service
- [ ] Testes de integração

#### Deploy (1 dia)
- [ ] Atualizar Docker Compose
- [ ] Variáveis de ambiente

---

## ETAPA 3: Yield + Multi-chain (15-20 dias)

### Objetivo
Dinheiro parado gera rendimento + suporte a Solana

### Custo por doação: ~1.00% (com yield cobrindo parte)

### Tasks

#### Aave Integration (3-4 dias)
- [ ] Setup Ethereum/Polygon sidecar
- [ ] AaveService: supply
- [ ] AaveService: withdraw
- [ ] AaveService: get_apy
- [ ] AaveService: get_balance
- [ ] Testes de integração

#### Solana Integration (3-4 dias)
- [ ] Setup Solana sidecar
- [ ] SolanaService: create_wallet
- [ ] SolanaService: transfer_usdt
- [ ] SolanaService: get_balance
- [ ] Testes de integração

#### Yield Monitoring (2-3 dias)
- [ ] Migration: yield_snapshots
- [ ] YieldService: calculate_earned
- [ ] YieldMonitorJob (Sidekiq)
- [ ] Alertas de APY baixo

#### Multi-chain Support (2-3 dias)
- [ ] Atualizar WalletsController
- [ ] Suporte a rede Solana
- [ ] Seleção de rede no frontend

#### Testes (2-3 dias)
- [ ] Testes de integração Aave
- [ ] Testes de integração Solana
- [ ] Testes de yield

#### Deploy (1-2 dias)
- [ ] Atualizar Docker Compose
- [ ] Variáveis de ambiente

---

## ETAPA 4: Escalar e Otimizar (Contínuo)

### Tasks
- [ ] Dashboard admin
- [ ] Notificações push
- [ ] Multi-idioma (PT/EN/ES)
- [ ] App mobile (React Native)
- [ ] Relatórios financeiros
- [ ] API pública para integrações
- [ ] Monitoring (Prometheus + Grafana)
- [ ] Alertas avançados
- [ ] Backup automático

---

## Timeline

| Fase | Dias | Dependências |
|------|------|--------------|
| **Etapa 1** | 15-20 | - |
| **Etapa 2** | 10-15 | Etapa 1 |
| **Etapa 3** | 15-20 | Etapa 1 |
| **Etapa 4** | Contínuo | Etapas 1-3 |
| **Total MVP** | **30-40** | - |

## Marcos Importantes

| Marco | Entregável |
|-------|------------|
| **MVP Funcional** | Doação funcionando (PIX → USDT → Wallet) |
| **Beta Fechado** | Doação + Saque funcionando |
| **Beta Aberto** | Yield + Multi-chain |
| **Lançamento** | Sistema completo com testes |

## Prioridades Pós-Lançamento

1. Dashboard admin
2. Multi-chain (Solana + Base)
3. Yield diversificado (Aave + Morpho)
4. Notificações push
5. App mobile (React Native)
