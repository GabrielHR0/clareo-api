# Clareo — Plano de Execução (MVP: Receber + Resgatar)

> Estratégia: Focar no essencial — receber doação e permitir resgate
> Meta: Validar fluxo completo de caixa com custo mínimo

---

## VISÃO GERAL

```
DOADOR                         PLATAFORMA                      INSTITUIÇÃO
  │                                │                                │
  │  1. Paga PIX                   │                                │
  │───────────────────────────────>│                                │
  │                                │  2. Converte USDT              │
  │                                │  3. Armazena na wallet         │
  │                                │                                │
  │                                │  4. Instituição solicita       │
  │                                │<───────────────────────────────│
  │                                │  5. Converte BRL               │
  │  6. PIX na conta               │  6. Envia PIX                  │
  │                                │───────────────────────────────>│
```

## ESCOPO MVP

| O que faz | O que NÃO faz (ainda) |
|-----------|----------------------|
| Receber doação via PIX | Yield / rendimento |
| Converter para USDT | Multi-chain (Solana) |
| Armazenar em wallet TRON | Dashboard admin |
| Consultar saldo | Notificações push |
| Solicitar saque | App mobile |
| Enviar PIX para instituição | |

---

## CUSTOS POR TRANSAÇÃO

### Doação de R$100

| Serviço | Taxa | Valor |
|---------|------|-------|
| NOWPayments (PIX) | 0.5% | R$0.50 |
| Binance (compra USDT) | 0.1% | R$0.10 |
| TRON (gas fee) | ~$0.14 | R$1.44 |
| **Total** | **2.04%** | **R$2.04** |

### Saque de R$100

| Serviço | Taxa | Valor |
|---------|------|-------|
| Binance (vende USDT) | 0.1% | R$0.10 |
| NOWPayments (envia PIX) | 0.5% | R$0.50 |
| **Total** | **0.60%** | **R$0.60** |

---

## STACK

| Componente | Tecnologia | Custo |
|------------|------------|-------|
| Backend | Rails 8.1 + Kino | $0 |
| Banco | PostgreSQL | $0 (local) |
| Cache | Redis | $0 (local) |
| Auth | JWT + bcrypt | $0 |
| Exchange | Binance API | 0.1% |
| Blockchain | TRON (TronWeb sidecar) | ~$1.44/tx |
| Gateway | NOWPayments (PIX) | 0.5% |
| Jobs | Sidekiq | $0 |

---

## MODELS

### User

```ruby
class User < ApplicationRecord
  has_secure_password
  has_many :wallets, dependent: :destroy
  has_many :donations, dependent: :destroy
  has_many :withdrawals, dependent: :destroy

  enum :role, { donor: 'donor', institution: 'institution', admin: 'admin' }

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :role, presence: true
end
```

### Wallet

```ruby
class Wallet < ApplicationRecord
  belongs_to :user
  has_many :donations, dependent: :nullify

  validates :address, presence: true, uniqueness: true
  validates :encrypted_private_key, presence: true

  scope :active, -> { where(active: true) }
end
```

### Donation

```ruby
class Donation < ApplicationRecord
  belongs_to :wallet, optional: true
  belongs_to :user, optional: true

  enum :status, { pending: 'pending', confirmed: 'confirmed', failed: 'failed' }

  validates :amount_brl, presence: true, numericality: { greater_than: 0 }
  validates :donor_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :payment_method, presence: true
end
```

### Withdrawal

```ruby
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

---

## MIGRATIONS

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

# 004_create_withdrawals.rb
class CreateWithdrawals < ActiveRecord::Migration[8.1]
  def change
    create_table :withdrawals do |t|
      t.references :user, null: false, foreign_key: true
      t.references :wallet, null: false, foreign_key: true
      t.decimal :amount_brl, precision: 15, scale: 2, null: false
      t.decimal :amount_usdt, precision: 20, scale: 6
      t.string :pix_key, null: false
      t.string :status, null: false, default: 'pending'
      t.decimal :fee_amount, precision: 15, scale: 2, default: 0
      t.string :tx_hash
      t.timestamps
    end
    add_index :withdrawals, :status
  end
end
```

---

## API ENDPOINTS

### Autenticação

```
POST   /api/v1/auth/register     → Cadastro
POST   /api/v1/auth/login        → Login
GET    /api/v1/auth/me           → Perfil
```

### Carteiras

```
POST   /api/v1/wallets           → Criar carteira TRON
GET    /api/v1/wallets           → Listar carteiras
GET    /api/v1/wallets/:id       → Detalhes da carteira + saldo
```

### Doações

```
POST   /api/v1/donations         → Criar doação (retorna payment_url)
GET    /api/v1/donations/:id     → Status da doação
GET    /api/v1/donations         → Listar doações
```

### Saques

```
POST   /api/v1/withdrawals       → Solicitar saque
GET    /api/v1/withdrawals/:id   → Status do saque
GET    /api/v1/withdrawals       → Listar saques
```

### Webhooks

```
POST   /api/v1/webhooks/nowpayments → Confirmação de pagamento
```

---

## SERVIÇOS (Strategy Pattern)

### Estrutura

```
app/services/
├── exchange_interface.rb
├── blockchain_interface.rb
├── payment_interface.rb
├── exchanges/
│   └── binance_service.rb
├── blockchains/
│   └── tron_service.rb
├── payments/
│   └── nowpayments_service.rb
├── donation_service.rb
└── withdrawal_service.rb
```

### ExchangeInterface

```ruby
module ExchangeInterface
  def buy_usdt(amount_brl); end
  def sell_usdt(amount_usdt); end
  def get_price; end
  def get_balance(asset); end
end
```

### BlockchainInterface

```ruby
module BlockchainInterface
  def create_wallet; end
  def get_balance(address); end
  def transfer_usdt(from_key, to_address, amount); end
end
```

### PaymentInterface

```ruby
module PaymentInterface
  def create_payment(amount_brl, order_id); end
  def send_pix(amount_brl, pix_key); end
  def verify_ipn_signature(signature, body); end
end
```

### DonationService

```ruby
class DonationService
  def initialize(exchange:, blockchain:, payment:)
    @exchange = exchange
    @blockchain = blockchain
    @payment = payment
  end

  def create(donation_params)
    # 1. Cria pagamento via NOWPayments
    # 2. Retorna payment_url para o doador
  end

  def confirm!(donation)
    # 1. Verifica webhook do NOWPayments
    # 2. Binance compra USDT
    # 3. TRON envia para wallet
    # 4. Atualiza status
  end
end
```

### WithdrawalService

```ruby
class WithdrawalService
  def initialize(exchange:, blockchain:, payment:)
    @exchange = exchange
    @blockchain = blockchain
    @payment = payment
  end

  def process!(withdrawal)
    # 1. Binance vende USDT → BRL
    # 2. NOWPayments envia PIX
    # 3. Atualiza status
  end
end
```

---

## FLUXO DETALHADO

### Receber Doação

```
1. Doador cria conta (POST /auth/register)
2. Doador cria carteira (POST /wallets)
   → TronWeb sidecar cria wallet TRON
   → Salva address + encrypted_private_key
3. Doador inicia doação (POST /donations)
   → NOWPayments cria pagamento
   → Retorna payment_url
4. Doador paga via PIX
5. NOWPayments webhook (POST /webhooks/nowpayments)
   → Verifica assinatura
   → Binance compra USDT
   → TronWeb envia USDT para carteira
   → Confirma doação
6. Doador recebe confirmação
```

### Resgatar (Saque)

```
1. Instituição solicita saque (POST /withdrawals)
   → Verifica saldo da wallet
   → Calcula USDT necessário
2. Binance vende USDT → BRL
3. NOWPayments envia PIX
4. Confirmação via webhook
5. PIX chega na conta da instituição
```

---

## CHECKLIST MVP

### Semana 1: Setup + Auth
- [ ] Configurar Kino (remover Puma)
- [ ] Migration: users, wallets, donations, withdrawals
- [ ] Auth: JWT encode/decode, login, register
- [ ] RSpec: testes de model

### Semana 2: Services
- [ ] ExchangeInterface + BinanceService
- [ ] BlockchainInterface + TronService
- [ ] PaymentInterface + NowPaymentsService
- [ ] RSpec: testes de services (mock)

### Semana 3: Controllers + Fluxo
- [ ] DonationsController: create, show, index
- [ ] WalletsController: create, index
- [ ] WithdrawalsController: create, show, index
- [ ] WebhooksController: nowpayments
- [ ] DonationService + WithdrawalService

### Semana 4: Teste + Deploy
- [ ] Teste end-to-end com sandbox
- [ ] Deploy staging
- [ ] Ajustes finais
- [ ] Deploy produção

---

## DECISÕES FUTURAS (fora do MVP)

| Item | Quando | Prioridade |
|------|--------|------------|
| Yield (Aave V3) | Após validação | Alta |
| Solana | Após yield | Média |
| Dashboard admin | Após stable | Média |
| Notificações | Após stable | Baixa |
| App mobile | Após scale | Baixa |

---

## REFERÊNCIAS

- Binance API: https://github.com/binance/binance-spot-api-docs/blob/master/rest-api.md
- TronWeb: https://developers.tron.network/docs/tronweb-1
- NOWPayments: https://documenter.getpostman.com/view/7907941/2s93JusNJt
- Regulamentação BR: https://www.bcb.gov.br/
