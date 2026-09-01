# Clareo — Roadmap de Implementação

## Fases de Desenvolvimento

### Fase 1: Setup (1 dia)

- [x] Instalar Ruby 4.0.6
- [x] Criar projeto Rails API (`rails new clareo --api --database=postgresql`)
- [x] Adicionar gem `kino` ao Gemfile
- [x] Criar `config/kino.rb` (workers, threads, mode :threaded)
- [x] Configurar PostgreSQL
- [x] Configurar Redis
- [x] Configurar Sidekiq
- [ ] Setup Docker Compose
- [ ] Configurar variáveis de ambiente
- [ ] Configurar RuboCop e linting

### Fase 2: Models e Database (2 dias)

- [ ] Migration: users
- [ ] Migration: wallets
- [ ] Migration: donations
- [ ] Migration: withdrawals
- [ ] Migration: yield_snapshots
- [ ] Migration: audit_logs
- [ ] Configurar associações
- [ ] Configurar validações
- [ ] Configurar indexes

### Fase 3: Autenticação (1 dia)

- [ ] Gem JWT
- [ ] AuthService.encode/decode
- [ ] AuthController (login/register)
- [ ] Middleware de autenticação
- [ ] Rate limiting

### Fase 4: Binance Integration (2 dias)

- [ ] Configurar API keys
- [ ] Service: get_usdt_brl_price
- [ ] Service: buy_usdt
- [ ] Service: sell_usdt
- [ ] Service: get_balance
- [ ] Testes de integração

### Fase 5: TRON Integration (3 dias)

- [ ] Setup Node.js sidecar
- [ ] Service: create_wallet
- [ ] Service: get_balance
- [ ] Service: transfer_usdt
- [ ] Service: get_transaction
- [ ] Configurar staking TRX
- [ ] Testes de integração

### Fase 6: JustLend Integration (2 dias)

- [ ] Service: get_apy
- [ ] Service: supply (depositar)
- [ ] Service: redeem (sacar)
- [ ] Service: get_balance
- [ ] YieldMonitorJob (Sidekiq)
- [ ] Testes de integração

### Fase 7: NOWPayments Integration (2 dias)

- [ ] Configurar API keys
- [ ] Service: create_payment
- [ ] Service: create_withdrawal
- [ ] Service: get_payment_status
- [ ] WebhooksController (IPN)
- [ ] Verificação de assinatura
- [ ] Testes de integração

### Fase 8: API REST (2 dias)

- [ ] DonationsController
- [ ] WalletsController
- [ ] WithdrawalsController
- [ ] YieldController
- [ ] Serializers/Validators
- [ ] Documentação Swagger/OpenAPI

### Fase 9: Sidekiq Jobs (1 dia)

- [ ] DonationConfirmJob
- [ ] WithdrawalProcessJob
- [ ] YieldMonitorJob
- [ ] WebhookProcessJob
- [ ] Configurar filas e prioridades

### Fase 10: Deploy (1 dia)

- [ ] Dockerfile
- [ ] docker-compose.yml
- [ ] Nginx config
- [ ] SSL (Let's Encrypt)
- [ ] Variáveis de ambiente
- [ ] Health check
- [ ] Backup automático

### Fase 11: Testes (2 dias)

- [ ] Configurar RSpec
- [ ] Testes de model
- [ ] Testes de service
- [ ] Testes de controller
- [ ] Testes de integração
- [ ] Testes de webhook

### Fase 12: Documentação (1 dia)

- [x] Visão geral
- [x] Arquitetura
- [x] Modelos de dados
- [x] Fluxos
- [x] Integrações
- [x] Segurança
- [x] Custos e receitas
- [x] Deploy
- [x] API endpoints
- [x] Referências
- [ ] README.md do projeto

---

## Timeline

| Fase | Dias | Dependências |
|------|------|--------------|
| 1. Setup | 1 | - |
| 2. Models | 2 | Fase 1 |
| 3. Auth | 1 | Fase 2 |
| 4. Binance | 2 | Fase 3 |
| 5. TRON | 3 | Fase 3 |
| 6. JustLend | 2 | Fase 5 |
| 7. NOWPayments | 2 | Fase 3 |
| 8. API | 2 | Fases 4-7 |
| 9. Jobs | 1 | Fase 8 |
| 10. Deploy | 1 | Fase 9 |
| 11. Testes | 2 | Fase 10 |
| 12. Docs | 1 | Fase 11 |
| **Total** | **20 dias** | - |

## Marcos Importantes

| Marco | Dia | Entregável |
|-------|-----|------------|
| MVP Funcional | 10 | API rodando com 3 integrações |
| Beta Fechado | 15 | Sistema completo com testes |
| Lançamento | 20 | Produção com documentação |

## Prioridades Pós-Lançamento

1. Dashboard admin
2. Notificações push
3. App mobile (React Native)
4. Multi-idioma (PT/EN/ES)
5. Relatórios financeiros
6. API pública para integrações
