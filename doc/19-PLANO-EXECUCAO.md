# Clareo — Plano de Execução (Máxima Economia + Validação)

> Estratégia: Construir em camadas, validar cada fluxo antes de avançar
> Meta: Custo mínimo por transação, compliance via parceiro

---

## VISÃO GERAL DAS ETAPAS

```
ETAPA 1          ETAPA 2           ETAPA 3          ETAPA 4
Validar Doação → Adicionar Saque → Yield + Multi-chain → Escalar
(15-20 dias)     (10-15 dias)      (15-20 dias)      (contínuo)
```

**Custo por doação R$100 por etapa:**
- Etapa 1: ~R$2.10 (2.1%)
- Etapa 2: ~R$1.60 (1.6%)
- Etapa 3: ~R$1.20 (1.2%)

---

## ETAPA 1 — VALIDAR DOAÇÃO (15-20 dias)

### Objetivo
Doador paga PIX → USDT chega na wallet → Pode confirmar receipt

### Stack Mínima
| Componente | Tecnologia | Custo |
|------------|------------|-------|
| Backend | Rails 8.1 + **Kino** (Rust) | $0 |
| Banco | PostgreSQL | $0 (local) |
| Cache | Redis | $0 (local) |
| Auth | JWT + bcrypt | $0 |
| On-ramp | Binance API | 0.1% |
| Blockchain | TRON (TronWeb sidecar) | ~$1.44/tx |
| Gateway | NOWPayments (PIX widget) | 0.5% |
| Jobs | Sidekiq | $0 |

**Custo total Etapa 1: ~2.1% por doação**

### Models Necessários

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password
  has_many :wallets, dependent: :destroy
  has_many :donations, dependent: :destroy
  
  enum :role, { donor: 'donor', beneficiary: 'beneficiary', admin: 'admin' }
  
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :role, presence: true
end

# app/models/wallet.rb
class Wallet < ApplicationRecord
  belongs_to :user
  has_many :donations, dependent: :nullify
  
  validates :address, presence: true, uniqueness: true
  validates :encrypted_private_key, presence: true
  
  scope :active, -> { where(active: true) }
end

# app/models/donation.rb
class Donation < ApplicationRecord
  belongs_to :wallet, optional: true
  belongs_to :user, optional: true
  
  enum :status, { pending: 'pending', confirmed: 'confirmed', failed: 'failed' }
  enum :payment_method, { pix: 'pix', card: 'card', boleto: 'boleto' }
  
  validates :amount_brl, presence: true, numericality: { greater_than: 0 }
  validates :donor_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :payment_method, presence: true
end
```

### API Endpoints (Etapa 1)

```
POST   /api/v1/auth/register     → Cadastro
POST   /api/v1/auth/login        → Login
GET    /api/v1/auth/me           → Perfil

POST   /api/v1/wallets           → Criar carteira TRON
GET    /api/v1/wallets           → Listar carteiras

POST   /api/v1/donations         → Criar doação (retorna payment_url)
GET    /api/v1/donations/:id     → Status da doação
GET    /api/v1/donations         → Listar doações

POST   /api/v1/webhooks/nowpayments → Webhook NOWPayments
```

### Fluxo Detalhado

```
1. Doador cria conta (POST /auth/register)
2. Doador cria carteira (POST /wallets)
   → TronWeb sidecar cria wallet TRON
   → Salva address + encrypted_private_key
3. Doador inicia doação (POST /donations)
   → NOWPayments cria pagamento (0.5%)
   → Retorna payment_url
4. Doador paga via PIX
5. NOWPayments webhook (POST /webhooks/nowpayments)
   → Verifica assinatura
   → Binance API compra USDT (0.1%)
   → TronWeb envia USDT para carteira (~$1.44)
   → Confirma doação
6. Doador recebe confirmação
```

### Serviços Necessários

```ruby
# app/services/binance_service.rb
class BinanceService
  BASE_URL = 'https://api.binance.com'
  
  def get_usdt_brl_price
    # GET /api/v3/ticker/price?symbol=USDTBRL
  end
  
  def buy_usdt(amount_brl)
    # POST /api/v3/order (MARKET BUY)
    # Calcula quantity baseado no preço + spread 0.2%
  end
  
  def get_balance(asset)
    # GET /api/v3/account
  end
end

# app/services/tron_service.rb (via sidecar)
class TronService
  SIDECAR_URL = ENV['TRON_SIDECAR_URL']
  
  def create_wallet
    # POST /wallet/create
  end
  
  def get_balance(address)
    # GET /wallet/:address/balance
  end
  
  def transfer_usdt(from_key, to_address, amount)
    # POST /wallet/transfer
  end
end

# app/services/nowpayments_service.rb
class NowPaymentsService
  BASE_URL = 'https://api.nowpayments.io'
  
  def create_payment(amount_brl, order_id)
    # POST /v1/payment
    # Retorna payment_url
  end
  
  def verify_ipn_signature(signature, body)
    # HMAC-SHA512
  end
end
```

### Migrations

```ruby
# 001_create_users.rb
class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :name, null: false
      t.string :role, null: false, default: 'donor'
      t.string :password_digest, null: false
      t.timestamps
    end
    add_index :users, :email, unique: true
    add_index :users, :role
  end
end

# 002_create_wallets.rb
class CreateWallets < ActiveRecord::Migration[8.1]
  def change
    create_table :wallets do |t|
      t.references :user, null: false, foreign_key: true
      t.string :address, null: false
      t.text :encrypted_private_key, null: false
      t.decimal :balance_usdt, precision: 20, scale: 6, default: 0
      t.string :network, null: false, default: 'tron'
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :wallets, :address, unique: true
    add_index :wallets, :active
  end
end

# 003_create_donations.rb
class CreateDonations < ActiveRecord::Migration[8.1]
  def change
    create_table :donations do |t|
      t.references :wallet, foreign_key: true
      t.references :user, foreign_key: true
      t.string :donor_name, null: false
      t.string :donor_email, null: false
      t.decimal :amount_brl, precision: 15, scale: 2, null: false
      t.decimal :amount_usdt, precision: 20, scale: 6
      t.string :tx_hash
      t.string :status, null: false, default: 'pending'
      t.decimal :fee_amount, precision: 15, scale: 2, default: 0
      t.string :payment_method, null: false
      t.string :nowpayments_id
      t.timestamps
    end
    add_index :donations, :status
    add_index :donations, :donor_email
    add_index :donations, :nowpayments_id
  end
end
```

### Checklist Etapa 1

- [ ] Setup: Puma, PostgreSQL, Redis, Sidekiq
- [ ] Migration: users, wallets, donations
- [ ] Auth: JWT encode/decode, login, register
- [ ] BinanceService: get_price, buy_usdt
- [ ] TronService: create_wallet, transfer (via sidecar)
- [ ] NowPaymentsService: create_payment, verify_ipn
- [ ] DonationsController: create, show, index
- [ ] WalletsController: create, index
- [ ] WebhooksController: nowpayments
- [ ] RSpec: models + services
- [ ] Teste end-to-end com sandbox

---

## ETAPA 2 — ADICIONAR SAQUE (10-15 dias)

### Objetivo
Beneficiário solicita saque → USDT vira BRL → PIX na conta

### Custo Etapa 2: ~1.6% por saque

### Models Adicionais

```ruby
# app/models/withdrawal.rb
class Withdrawal < ApplicationRecord
  belongs_to :user
  belongs_to :wallet
  
  enum :status, { 
    pending: 'pending', 
    processing: 'processing', 
    completed: 'completed', 
    failed: 'failed' 
  }
  
  validates :amount_brl, presence: true, numericality: { greater_than: 0 }
  validates :pix_key, presence: true
end
```

### API Endpoints (Adicionar)

```
POST   /api/v1/withdrawals           → Solicitar saque
GET    /api/v1/withdrawals/:id       → Status do saque
GET    /api/v1/withdrawals           → Listar saques
```

### Fluxo Saque

```
1. Beneficiário solicita saque (POST /withdrawals)
   → Calcula USDT necessário
   → Verifica saldo JustLend/wallet
2. Binance vende USDT → BRL (0.1%)
3. NOWPayments envia PIX (0.5%)
4. Confirmação via webhook
```

### Serviço Adicional

```ruby
# app/services/withdrawal_service.rb
class WithdrawalService
  def process!(withdrawal)
    # 1. Redeem do yield (se aplicável)
    # 2. Binance vende USDT
    # 3. NOWPayments envia PIX
    # 4. Atualiza status
  end
end
```

---

## ETAPA 3 — YIELD + MULTI-CHAIN (15-20 dias)

### Objetivo
Dinheiro parado gera rendimento + suporte a Solana

### Custo Etapa 3: ~1.2% por doação (com yield cobrindo parte)

### Yield: Aave V3 (não JustLend)

```ruby
# app/services/yield_service.rb
class YieldService
  PROTOCOLS = {
    aave: { apy_range: 3..5, risk: :low },
    morpho: { apy_range: 4..7, risk: :medium }
  }
  
  def deposit_to_aave(amount, wallet)
    # Via sidecar Ethereum/Polygon
    # USDT → aUSDT (yield-bearing token)
  end
  
  def withdraw_from_aave(amount, wallet)
    # aUSDT → USDT
  end
  
  def get_current_apy
    # Consulta Aave pool
  end
end
```

### Solana Integration

```ruby
# app/services/solana_service.rb
class SolanaService
  def create_wallet
    # Gera keypair Solana
  end
  
  def transfer_usdt(from_keypair, to_address, amount)
    # SPL token transfer
    # Fee: ~$0.0004
  end
end
```

### Models Adicionais

```ruby
# app/models/yield_snapshot.rb
class YieldSnapshot < ApplicationRecord
  belongs_to :wallet
  
  validates :balance, presence: true
  validates :apy, presence: true
  validates :earned, presence: true
end
```

### Job: YieldMonitorJob

```ruby
class YieldMonitorJob < ApplicationJob
  queue_as :default
  
  def perform
    Wallet.active.each do |wallet|
      balance = YieldService.get_balance(wallet)
      apy = YieldService.get_current_apy
      
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

---

## ETAPA 4 — ESCALAR E OTIMIZAR (Contínuo)

### Otimizações
- [ ] Rate limiting por endpoint
- [ ] Cache de preços USDT (TTL 30s)
- [ ] Monitoring (Prometheus + Grafana)
- [ ] Alertas de APY baixo
- [ ] Backup automático

### Features Adicionais
- [ ] Dashboard admin
- [ ] Notificações push
- [ ] Multi-idioma
- [ ] App mobile
- [ ] API pública

---

## CUSTO TOTAL COMPARADO

### Doação de R$100

| Etapa | On-ramp | Trading | Blockchain | Total | % |
|-------|---------|---------|------------|-------|---|
| **Atual (docs)** | R$1.50 | R$0.20 | R$1.44 | R$3.14 | 3.14% |
| **Etapa 1** | R$0.50 | R$0.10 | R$1.44 | R$2.04 | 2.04% |
| **Etapa 2** | R$0.50 | R$0.10 | R$1.44 | R$2.04 | 2.04% |
| **Etapa 3** | R$0.50 | R$0.10 | R$0.60* | R$1.20 | 1.20% |

*Etapa 3 usa yield para cobrir parcialmente gas fees

### Saque de R$100

| Etapa | Trading | Off-ramp | Total | % |
|-------|---------|----------|-------|---|
| **Atual (docs)** | R$0.20 | R$1.50 | R$1.70 | 1.70% |
| **Etapa 2** | R$0.10 | R$0.50 | R$0.60 | 0.60% |
| **Etapa 3** | R$0.10 | R$0.50 | R$0.60 | 0.60% |

---

## ECONOMIA ANUAL PROJETADA

### Com R$100.000/mês em doações

| Cenário | Custo Mensal | Custo Anual | Economia Anual |
|---------|--------------|-------------|----------------|
| Modelo Atual | R$3.140 | R$37.680 | - |
| Etapa 1 | R$2.040 | R$24.480 | R$13.200 |
| Etapa 3 | R$1.200 | R$14.400 | R$23.280 |

---

## DECISÕES CHAVE

### 1. Parceiro Compliance (OBRIGATÓRIO)

**Recomendação:** Usar **Mercado Bitcoin** ou **Foxbit** como SPSAV licenciado

| Opção | Prós | Contras |
|-------|------|---------|
| **Mercado Bitcoin** | Maior exchange BR, compliance forte | Taxas maiores (0.3-0.7%) |
| **Foxbit** | Boa reputação, PIX nativo | Menor que MB |
| **Binance BR** | Menores taxas (0.1%) | Status regulatório incerto |

**Decisão:** Binance API para trading + exchange BR para compliance

### 2. Blockchain Primário

**Decisão:** TRON como primário (52% do mercado, deepest liquidity)

**Adicionar:** Solana como opção secundária para micro-transações

### 3. Yield Protocol

**Decisão:** Aave V3 como primário (3-5% APY, battle-tested)

**Não usar:** JustLend (1.35% é muito baixo)

---

## PRÓXIMOS PASSOS IMEDIATOS

### Esta Semana
1. ~~Criar este doc de plano~~ ✅
2. Decidir parceiro compliance (MB ou Foxbit)
3. Verificar se Binance API funciona para BRL/USDT
4. Setup projeto: Puma, models, auth

### Próxima Semana
5. BinanceService: get_price + buy_usdt
6. TronSidecar: create_wallet + transfer
7. DonationsController: create + webhook
8. Teste end-to-end com sandbox

### Semana 3
9. WithdrawalService: process saque
10. WebhookNOWPayments: confirm + fail
11. RSpec: testes completos
12. Deploy staging

### Semana 4
13. YieldService: Aave integration
14. SolanaService: multi-chain
15. Monitoramento + alertas
16. Deploy produção

---

## RISCOS E MITIGAÇÕES

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| Binance API instável | Alto | Fallback para BingX |
| TRON gas spike | Médio | energy rental service |
| Aave smart contract bug | Alto | Diversificar protocolos |
| Regulamentação muda | Alto | Parceiro compliance atualiza |
| NOWPayments fora do ar | Médio | Webhook retry + fallback |

---

## REFERÊNCIAS

- Doc 18-ANALISE-PLANEJAMENTO.md (pesquisa completa)
- Binance API: https://developers.binance.com/
- TronWeb: https://developers.tron.network/docs/tronweb-1
- Aave V3: https://docs.aave.com/
- NOWPayments: https://documenter.getpostman.com/view/7907941/2s93JusNJt
- Regulamentação BR: https://www.bcb.gov.br/
