# Clareo — Planejamento com Lexxen

## Provider Único: Lexxen Hub

Uma única API para receber PIX, converter para USDT, armazenar e enviar PIX para instituição.

### Documentação

- **API:** https://cashout.lexxen.com/docs
- **Sandbox:** Mesma URL, chave `lxn_test_...`
- **Produção:** Chave `lxn_...`

---

## Fluxo Completo

### Receber Doação

```
1. POST /quotes          → Cria cotação (trava preço)
2. POST /orders          → Gera PIX (retorna pix_copy_paste)
3. Doador paga PIX
4. Webhook: completed    → USDT cai na wallet
```

### Resgatar (Saque)

```
1. POST /sell/quotes     → Cria cotação de venda
2. POST /sell/orders     → Gera endereço de depósito
3. Instituição envia USDT para o endereço
4. Webhook: completed    → PIX enviado para chave PIX
```

---

## Taxas

| Operação | Taxa |
|----------|------|
| On-ramp (PIX → USDT) | 3% + fixa + rede |
| Off-ramp (USDT → PIX) | 1.5% + fixa + R$3.50 |

### Custo por Doação R$100

| Item | Valor |
|------|-------|
| On-ramp (3%) | R$3.00 |
| **Total** | **R$3.00** |

### Custo por Saque R$100

| Item | Valor |
|------|-------|
| Off-ramp (1.5%) | R$1.50 |
| Pix shipping | R$3.50 |
| **Total** | **R$5.00** |

---

## Stack

| Camada | Tecnologia |
|--------|------------|
| Backend | Ruby + Rails (API mode) |
| Banco | PostgreSQL |
| Cache/Filas | Redis + Sidekiq |
| Auth | JWT + bcrypt |
| Provider | Lexxen Hub (PIX ↔ USDT) |

---

## Models

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

  validates :lexxen_wallet_id, presence: true, uniqueness: true
  validates :address, presence: true
  validates :network, presence: true

  scope :active, -> { where(active: true) }
end
```

### Donation

```ruby
class Donation < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :wallet, optional: true

  enum :status, {
    pending: 'pending',
    processing: 'processing',
    completed: 'completed',
    failed: 'failed'
  }

  validates :amount_brl, presence: true, numericality: { greater_than: 0 }
  validates :donor_email, presence: true
  validates :lexxen_order_id, presence: true, on: :update
end
```

### Withdrawal

```ruby
class Withdrawal < ApplicationRecord
  belongs_to :user
  belongs_to :wallet

  enum :status, {
    pending: 'pending',
    awaiting_deposit: 'awaiting_deposit',
    processing: 'processing',
    completed: 'completed',
    failed: 'failed'
  }

  validates :amount_brl, presence: true, numericality: { greater_than: 0 }
  validates :pix_key, presence: true
end
```

---

## Migrations

```ruby
# 001_create_users.rb
class CreateUsers < ActiveRecord::Migration[8.0]
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
class CreateWallets < ActiveRecord::Migration[8.0]
  def change
    create_table :wallets do |t|
      t.references :user, null: false, foreign_key: true
      t.string :lexxen_wallet_id, null: false
      t.string :address, null: false
      t.string :network, null: false, default: 'polygon'
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :wallets, :lexxen_wallet_id, unique: true
    add_index :wallets, :address
  end
end

# 003_create_donations.rb
class CreateDonations < ActiveRecord::Migration[8.0]
  def change
    create_table :donations do |t|
      t.references :user, foreign_key: true
      t.references :wallet, foreign_key: true
      t.string :donor_name, null: false
      t.string :donor_email, null: false
      t.decimal :amount_brl, precision: 15, scale: 2, null: false
      t.decimal :amount_usdt, precision: 20, scale: 8
      t.string :lexxen_order_id
      t.string :lexxen_quote_id
      t.string :status, null: false, default: 'pending'
      t.decimal :fee_amount, precision: 15, scale: 2, default: 0
      t.string :tx_hash
      t.timestamps
    end
    add_index :donations, :status
    add_index :donations, :donor_email
    add_index :donations, :lexxen_order_id
  end
end

# 004_create_withdrawals.rb
class CreateWithdrawals < ActiveRecord::Migration[8.0]
  def change
    create_table :withdrawals do |t|
      t.references :user, null: false, foreign_key: true
      t.references :wallet, null: false, foreign_key: true
      t.decimal :amount_brl, precision: 15, scale: 2, null: false
      t.decimal :amount_usdt, precision: 20, scale: 8
      t.string :pix_key, null: false
      t.string :lexxen_order_id
      t.string :lexxen_quote_id
      t.string :status, null: false, default: 'pending'
      t.decimal :fee_amount, precision: 15, scale: 2, default: 0
      t.string :tx_hash
      t.timestamps
    end
    add_index :withdrawals, :status
    add_index :withdrawals, :lexxen_order_id
  end
end
```

---

## Serviços

### LexxenService

```ruby
# app/services/lexxen_service.rb
class LexxenService
  BASE_URL = 'https://cashout.lexxen.com/api/v1'

  def initialize
    @api_key = ENV['LEXXEN_API_KEY']
    @api_secret = ENV['LEXXEN_API_SECRET']
  end

  # On-ramp: PIX → USDT
  def create_quote(amount_brl:, asset:, network:, wallet_address:)
    # POST /quotes
  end

  def create_order(quote_id:, external_id: nil)
    # POST /orders
  end

  def get_order(id)
    # GET /orders/{id}
  end

  # Off-ramp: USDT → PIX
  def create_sell_quote(amount_crypto:, asset:, network:)
    # POST /sell/quotes
  end

  def create_sell_order(quote_id:, sender_address:, receiver_pix_key:, external_id: nil)
    # POST /sell/orders
  end

  def get_sell_order(id)
    # GET /sell/orders/{id}
  end

  # Wallets
  def list_wallets
    # GET /wallets
  end

  def validate_wallet(address:, network:)
    # POST /wallets/validate
  end

  # Balance
  def get_balance
    # GET /balance
  end

  # Webhook verification
  def verify_webhook(signature:, body:)
    # HMAC-SHA256 verification
  end

  private

  def signed_request(method, path, body: nil)
    timestamp = Time.now.to_i.to_s
    payload = timestamp + method.upcase + path + (body || '')
    signature = OpenSSL::HMAC.hexdigest('SHA256', @api_secret, payload)

    uri = URI("#{BASE_URL}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = case method.upcase
    when 'GET' then Net::HTTP::Get.new(uri)
    when 'POST' then Net::HTTP::Post.new(uri)
    end

    request['X-API-Key'] = @api_key
    request['X-Timestamp'] = timestamp
    request['X-Signature'] = signature
    request['Content-Type'] = 'application/json'
    request.body = body if body

    response = http.request(request)
    JSON.parse(response.body)
  end
end
```

---

## API Endpoints

### Autenticação

```
POST   /api/v1/auth/register     → Cadastro
POST   /api/v1/auth/login        → Login
GET    /api/v1/auth/me           → Perfil
```

### Carteiras

```
GET    /api/v1/wallets           → Listar carteiras
POST   /api/v1/wallets           → Criar carteira (via Lexxen)
```

### Doações

```
POST   /api/v1/donations         → Criar doação (retorna QR PIX)
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
POST   /api/v1/webhooks/lexxen   → Eventos Lexxen
```

---

## Fluxo Detalhado: Receber Doação

```
1. Doador cria conta (POST /auth/register)
2. Doador cria carteira (POST /wallets)
   → LexxenService.list_wallets → salva wallet_id
3. Doador inicia doação (POST /donations)
   → LexxenService.create_quote(amount_brl: 100, asset: "USDT", network: "polygon", wallet_address: "0x...")
   → LexxenService.create_order(quote_id)
   → Retorna pix_copy_paste
4. Doador paga via PIX
5. Lexxen webhook (POST /webhooks/lexxen)
   → LexxenService.verify_webhook
   → Atualiza Donation status: completed
   → Atualiza Wallet saldo
```

---

## Fluxo Detalhado: Solicitar Saque

```
1. Instituição solicita saque (POST /withdrawals)
   → LexxenService.create_sell_quote(amount_crypto: 18.52, asset: "USDT", network: "polygon")
   → LexxenService.create_sell_order(quote_id, wallet_address, pix_key)
   → Retorna deposit_address
2. Lexxen envia USDT para o deposit_address
3. Lexxen webhook (POST /webhooks/lexxen)
   → LexxenService.verify_webhook
   → Atualiza Withdrawal status: completed
   → PIX enviado para a instituição
```

---

## Checklist MVP

### Semana 1: Setup
- [ ] Configurar Rails + PostgreSQL + Redis
- [ ] Migration: users, wallets, donations, withdrawals
- [ ] Auth: JWT encode/decode, login, register
- [ ] Configurar Lexxen sandbox

### Semana 2: Services
- [ ] LexxenService: create_quote, create_order
- [ ] LexxenService: create_sell_quote, create_sell_order
- [ ] LexxenService: verify_webhook
- [ ] DonationService: create, confirm
- [ ] WithdrawalService: process

### Semana 3: Controllers + Fluxo
- [ ] DonationsController: create, show, index
- [ ] WalletsController: create, index
- [ ] WithdrawalsController: create, show, index
- [ ] WebhooksController: lexxen
- [ ] RSpec: testes de service (mock)

### Semana 4: Teste + Deploy
- [ ] Teste end-to-end com sandbox Lexxen
- [ ] Deploy staging
- [ ] Deploy produção
