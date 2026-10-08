# Clareo — Planejamento com Asaas Split Payment

## Arquitetura

Doador paga PIX → Asaas recebe → Split automático → Instituições recebem.

**O Clareo NUNCA segura dinheiro de terceiros.**

```
┌──────────┐     PIX      ┌──────────┐    Split     ┌──────────┐
│  Doador  │ ───────────→ │  Asaas   │ ──────────→ │Instituição│
│          │              │  (PSP)   │ ──────────→ │    A     │
└──────────┘              └──────────┘             └──────────┘
                               │
                               │ Clareo recebe
                               │ comissão (se aplicável)
                               ↓
                        ┌──────────┐
                        │  Clareo  │
                        │  (API)   │
                        └──────────┘
```

---

## Provider Único: Asaas

Uma única API para receber PIX, fazer split e transferir para instituições.

### Documentação

- **API:** https://docs.asaas.com/reference
- **Sandbox:** https://sandbox.asaas.com/api/v3
- **Produção:** https://api.asaas.com/v3

---

## Fluxo Completo

### Receber Doação

```
1. Clareo cria subconta para instituição (se não existe)
2. Doador acessa link de pagamento Clareo
3. Asaas gera QR Code PIX (dinâmico, com splits)
4. Doador paga PIX
5. Webhook: PAYMENT_RECEIVED → Clareo registra doação
6. Split automático → instituições recebem
```

### Institution Withdraw (Saques)

```
Instituição recebe o split diretamente na subconta Asaas.
Para sacar, instituição usa a conta Asaas dela (PIX, TED, etc).
Clareo não participa do saque — é entre instituição e Asaas.
```

---

## Taxas

| Operação | Taxa |
|----------|------|
| PIX recebido | R$ 0,49 por transação |
| Split para subcontas | Grátis |
| Transferência PIX (saída) | Grátis até 30/mês, depois R$ 2,00 |
| Conta PJ | Grátis |
| Mensalidade | Grátis |
| API | Grátis |
| Webhooks | Grátis |

### Custo por Doação R$100

| Item | Valor |
|------|-------|
| Taxa PIX recebido | R$ 0,49 |
| Split | R$ 0,00 |
| **Total** | **R$ 0,49** |

---

## Stack

| Camada | Tecnologia |
|--------|------------|
| Backend | Ruby + Rails (API mode) |
| Banco | PostgreSQL |
| Cache/Filas | Redis + Sidekiq |
| Auth | JWT + bcrypt |
| Provider | Asaas Split Payment |

---

## Models

### User

```ruby
class User < ApplicationRecord
  has_secure_password
  has_many :donations, dependent: :destroy
  has_many :institutions, dependent: :destroy

  enum :role, { donor: 'donor', institution: 'institution', admin: 'admin' }

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :role, presence: true
end
```

### Institution

```ruby
class Institution < ApplicationRecord
  belongs_to :user
  has_many :donation_splits, dependent: :destroy

  validates :name, presence: true
  validates :cnpj, presence: true, uniqueness: true
  validates :asaas_customer_id, presence: true, uniqueness: true
  validates :asaas_wallet_id, presence: true, uniqueness: true
  validates :pix_key, presence: true

  scope :active, -> { where(active: true) }
end
```

### Donation

```ruby
class Donation < ApplicationRecord
  belongs_to :user, optional: true
  has_many :donation_splits, dependent: :destroy

  enum :status, {
    pending: 'pending',
    received: 'received',
    split_done: 'split_done',
    failed: 'failed',
    refunded: 'refunded'
  }

  validates :amount_brl, presence: true, numericality: { greater_than: 0 }
  validates :donor_name, presence: true
  validates :donor_email, presence: true
  validates :asaas_payment_id, presence: true, uniqueness: true
end
```

### DonationSplit

```ruby
class DonationSplit < ApplicationRecord
  belongs_to :donation
  belongs_to :institution

  enum :status, {
    pending: 'pending',
    awaiting_credit: 'awaiting_credit',
    done: 'done',
    cancelled: 'cancelled',
    refused: 'refused',
    refunded: 'refunded'
  }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :asaas_split_id, presence: true
end
```

### Campaign

```ruby
class Campaign < ApplicationRecord
  belongs_to :institution
  has_many :donations, dependent: :nullify

  enum :status, { active: 'active', paused: 'paused', closed: 'closed' }

  validates :title, presence: true
  validates :description, presence: true
  validates :goal_amount, presence: true, numericality: { greater_than: 0 }
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :status, presence: true

  scope :active, -> { where(status: 'active') }
  scope :public_feed, -> { where(status: ['active', 'paused']) }

  def expired?
    end_date < Date.current
  end

  def progress_percent
    return 0 if goal_amount.zero?
    ((current_amount / goal_amount) * 100).round(1)
  end
end
```

### Post (Transparência)

```ruby
class Post < ApplicationRecord
  belongs_to :institution
  has_many :post_attachments, dependent: :destroy

  enum :post_type, { update: 'update', receipt: 'receipt', report: 'report' }

  validates :title, presence: true
  validates :content, presence: true
  validates :post_type, presence: true
  validates :published_at, presence: true

  scope :published, -> { where('published_at <= ?', Time.current) }
  scope :by_institution, ->(inst) { where(institution: inst) }
end
```

### PostAttachment

```ruby
class PostAttachment < ApplicationRecord
  belongs_to :post

  validates :file_url, presence: true
  validates :file_type, presence: true
end
```

### Subscription

```ruby
class Subscription < ApplicationRecord
  belongs_to :institution

  enum :plan, { free: 'free', pro: 'pro' }
  enum :status, { active: 'active', canceled: 'canceled', expired: 'expired' }

  validates :plan, presence: true
  validates :status, presence: true

  scope :active_pro, -> { where(plan: 'pro', status: 'active') }

  def pro?
    plan == 'pro' && status == 'active'
  end

  def features
    if pro?
      %i[transparency campaigns reports finance]
    else
      %i[basic_donations]
    end
  end
end
```

### DonationReport

```ruby
class DonationReport < ApplicationRecord
  belongs_to :institution

  enum :format, { pdf: 'pdf', csv: 'csv' }

  validates :period_start, presence: true
  validates :period_end, presence: true
  validates :format, presence: true

  scope :recent, -> { order(generated_at: :desc) }
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

# 002_create_institutions.rb
class CreateInstitutions < ActiveRecord::Migration[8.0]
  def change
    create_table :institutions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :cnpj, null: false
      t.string :asaas_customer_id, null: false
      t.string :asaas_wallet_id, null: false
      t.string :pix_key, null: false
      t.string :description
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :institutions, :cnpj, unique: true
    add_index :institutions, :asaas_customer_id, unique: true
    add_index :institutions, :asaas_wallet_id, unique: true
  end
end

# 003_create_donations.rb
class CreateDonations < ActiveRecord::Migration[8.0]
  def change
    create_table :donations do |t|
      t.references :user, foreign_key: true
      t.string :donor_name, null: false
      t.string :donor_email, null: false
      t.decimal :amount_brl, precision: 15, scale: 2, null: false
      t.decimal :fee_amount, precision: 15, scale: 2, default: 0
      t.decimal :net_amount, precision: 15, scale: 2, default: 0
      t.string :asaas_payment_id, null: false
      t.string :asaas_payment_url
      t.string :status, null: false, default: 'pending'
      t.jsonb :metadata, default: {}
      t.timestamps
    end
    add_index :donations, :status
    add_index :donations, :donor_email
    add_index :donations, :asaas_payment_id, unique: true
  end
end

# 004_create_donation_splits.rb
class CreateDonationSplits < ActiveRecord::Migration[8.0]
  def change
    create_table :donation_splits do |t|
      t.references :donation, null: false, foreign_key: true
      t.references :institution, null: false, foreign_key: true
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.decimal :percentual, precision: 5, scale: 2
      t.string :asaas_split_id, null: false
      t.string :status, null: false, default: 'pending'
      t.jsonb :metadata, default: {}
      t.timestamps
    end
    add_index :donation_splits, :status
    add_index :donation_splits, :asaas_split_id, unique: true
  end
end

# 005_create_campaigns.rb
class CreateCampaigns < ActiveRecord::Migration[8.0]
  def change
    create_table :campaigns do |t|
      t.references :institution, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description, null: false
      t.decimal :goal_amount, precision: 15, scale: 2, null: false
      t.decimal :current_amount, precision: 15, scale: 2, default: 0
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.string :cover_image_url
      t.string :status, null: false, default: 'active'
      t.timestamps
    end
    add_index :campaigns, :status
    add_index :campaigns, [:institution_id, :status]
  end
end

# 006_create_posts.rb
class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.references :institution, null: false, foreign_key: true
      t.string :title, null: false
      t.text :content, null: false
      t.string :post_type, null: false, default: 'update'
      t.datetime :published_at, null: false
      t.timestamps
    end
    add_index :posts, :post_type
    add_index :posts, [:institution_id, :published_at]
  end
end

# 007_create_post_attachments.rb
class CreatePostAttachments < ActiveRecord::Migration[8.0]
  def change
    create_table :post_attachments do |t|
      t.references :post, null: false, foreign_key: true
      t.string :file_url, null: false
      t.string :file_type, null: false
      t.string :description
      t.timestamps
    end
  end
end

# 008_create_subscriptions.rb
class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :institution, null: false, foreign_key: true
      t.string :plan, null: false, default: 'free'
      t.string :status, null: false, default: 'active'
      t.decimal :amount, precision: 10, scale: 2, default: 0
      t.string :asaas_subscription_id
      t.date :current_period_start
      t.date :current_period_end
      t.timestamps
    end
    add_index :subscriptions, [:institution_id, :plan]
    add_index :subscriptions, :status
  end
end

# 009_create_donation_reports.rb
class CreateDonationReports < ActiveRecord::Migration[8.0]
  def change
    create_table :donation_reports do |t|
      t.references :institution, null: false, foreign_key: true
      t.date :period_start, null: false
      t.date :period_end, null: false
      t.string :format, null: false, default: 'pdf'
      t.string :file_url
      t.datetime :generated_at
      t.decimal :total_donations, precision: 15, scale: 2, default: 0
      t.decimal :total_amount, precision: 15, scale: 2, default: 0
      t.decimal :average_donation, precision: 15, scale: 2, default: 0
      t.jsonb :summary, default: {}
      t.timestamps
    end
    add_index :donation_reports, [:institution_id, :generated_at]
  end
end
```

---

## Serviços

### AsaasService

```ruby
# app/services/asaas_service.rb
class AsaasService
  BASE_URL = 'https://api.asaas.com/v3'

  def initialize
    @api_key = ENV['ASAAS_API_KEY']
  end

  # --- Clientes (Instituições) ---

  def create_customer(name:, cpf_cnpj:, email:)
    post('/customers', {
      name: name,
      cpfCnpj: cpf_cnpj,
      email: email
    })
  end

  def get_customer(id)
    get("/customers/#{id}")
  end

  # --- Subcontas (Wallets) ---

  def create_subaccount(name:, cpf_cnpj:, email:)
    post('/subaccounts', {
      name: name,
      cpfCnpj: cpf_cnpj,
      email: email,
      profileType: 'JURIDICAL'
    })
  end

  def get_wallet(wallet_id)
    get("/wallets/#{wallet_id}")
  end

  # --- Cobranças com Split ---

  def create_payment(customer_id:, amount:, description:, splits:)
    post('/payments', {
      customer: customer_id,
      billingType: 'PIX',
      value: amount,
      description: description,
      splits: splits.map { |s|
        { walletId: s[:wallet_id], percentualValue: s[:percentual] }
      }
    })
  end

  def get_payment(id)
    get("/payments/#{id}")
  end

  def list_payments(params = {})
    get('/payments', params)
  end

  # --- Transferências ---

  def create_transfer(wallet_id:, amount:, pix_key:)
    post('/transfers', {
      walletId: wallet_id,
      value: amount,
      transferPix: {
        pixKey: pix_key
      }
    })
  end

  # --- Webhook Verification ---

  def self.verify_webhook(signature:, body:)
    # Asaas usa assinatura no header
    # Verificar documentação específica
    true # TODO: implementar verificação real
  end

  private

  def post(path, body)
    request(:post, path, body)
  end

  def get(path, params = nil)
    request(:get, path, params)
  end

  def request(method, path, body = nil)
    uri = URI("#{BASE_URL}#{path}")
    uri.query = URI.encode_www_form(body) if method == :get && body

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    case method
    when :get
      req = Net::HTTP::Get.new(uri)
    when :post
      req = Net::HTTP::Post.new(uri)
      req.body = body.to_json if body
    end

    req['Content-Type'] = 'application/json'
    req['access_token'] = @api_key

    response = http.request(req)
    JSON.parse(response.body)
  end
end
```

### DonationService

```ruby
# app/services/donation_service.rb
class DonationService
  def create(donor_name:, donor_email:, amount_brl:, institution_ids:)
    # 1. Buscar instituições
    institutions = Institution.where(id: institution_ids, active: true)

    # 2. Calcular splits (ex: dividir igualmente)
    split_count = institutions.count
    percentual_per_institution = 100.0 / split_count

    # 3. Montar array de splits
    splits = institutions.map do |inst|
      {
        wallet_id: inst.asaas_wallet_id,
        percentual: percentual_per_institution
      }
    end

    # 4. Criar pagamento no Asaas
    asaas = AsaasService.new
    payment = asaas.create_payment(
      customer_id: institutions.first.asaas_customer_id,
      amount: amount_brl,
      description: "Doação para #{institutions.map(&:name).join(', ')}",
      splits: splits
    )

    # 5. Criar registro no banco
    donation = Donation.create!(
      donor_name: donor_name,
      donor_email: donor_email,
      amount_brl: amount_brl,
      asaas_payment_id: payment['id'],
      asaas_payment_url: payment['invoiceUrl'],
      status: 'pending'
    )

    # 6. Criar registros de split
    institutions.each_with_index do |inst, i|
      DonationSplit.create!(
        donation: donation,
        institution: inst,
        amount: amount_brl * percentual_per_institution / 100,
        percentual: percentual_per_institution,
        asaas_split_id: payment['splits'][i]['id'],
        status: 'pending'
      )
    end

    donation
  end

  def confirm(asaas_payment_id)
    donation = Donation.find_by!(asaas_payment_id: asaas_payment_id)

    payment = AsaasService.new.get_payment(asaas_payment_id)

    case payment['status']
    when 'RECEIVED'
      donation.update!(status: 'received')
    when 'CONFIRMED'
      donation.update!(status: 'split_done')
    when 'OVERDUE', 'DELETED'
      donation.update!(status: 'failed')
    end

    donation
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

### Instituições

```
GET    /api/v1/institutions           → Listar instituições
POST   /api/v1/institutions           → Cadastrar instituição
GET    /api/v1/institutions/:id       → Detalhes da instituição
```

### Doações

```
POST   /api/v1/donations              → Criar doação (retorna QR PIX)
GET    /api/v1/donations/:id          → Status da doação
GET    /api/v1/donations              → Listar doações
```

### Campanhas

```
POST   /api/v1/campaigns              → Criar campanha (Pro)
GET    /api/v1/campaigns              → Listar campanhas (público)
GET    /api/v1/campaigns/:id          → Detalhes da campanha
PUT    /api/v1/campaigns/:id          → Editar campanha (Pro)
DELETE /api/v1/campaigns/:id          → Encerrar campanha (Pro)
```

### Transparência (Feed Público)

```
POST   /api/v1/posts                  → Criar post (Pro)
GET    /api/v1/posts                  → Listar posts (público)
GET    /api/v1/posts/:id              → Detalhes do post
PUT    /api/v1/posts/:id              → Editar post (Pro)
DELETE /api/v1/posts/:id              → Excluir post (Pro)
```

### Relatórios

```
POST   /api/v1/reports                → Gerar relatório (Pro)
GET    /api/v1/reports                → Listar relatórios (Pro)
GET    /api/v1/reports/:id/download   → Baixar relatório (Pro)
```

### Assinatura

```
GET    /api/v1/subscription           → Ver plano atual
POST   /api/v1/subscription/upgrade   → Fazer upgrade (Pro)
POST   /api/v1/subscription/cancel    → Cancelar assinatura
GET    /api/v1/subscription/invoices  → Ver faturas
```

### Financeiro (Pro)

```
GET    /api/v1/finance/balance        → Saldo detalhado
GET    /api/v1/finance/transactions   → Histórico de transações
GET    /api/v1/finance/summary        → Resumo financeiro
```

### Webhooks

```
POST   /api/v1/webhooks/asaas         → Eventos Asaas
```

---

## Fluxo Detalhado: Receber Doação

```
1. Doador acessa link de pagamento (ou gera via API)
   → DonationService.create(donor_name, donor_email, amount, institutions)

2. Clareo cria pagamento no Asaas com splits
   → POST /payments { customer, billingType: "PIX", value: 100, splits: [...] }

3. Asaas retorna QR Code + pix_copy_paste
   → Retorna para o doador

4. Doador paga via PIX

5. Asaas webhook (POST /webhooks/asaas)
   → Evento: PAYMENT_RECEIVED
   → DonationService.confirm(payment_id)
   → Donation status: received

6. Split automático
   → Asaas envia % para cada instituição
   → DonationSplit status: done
```

---

## Fluxo Detalhado: Instituição Recebe

```
Instituição tem subconta Asaas (asaas_wallet_id).
Split é creditado automaticamente na subconta.
Instituição usa conta Asaas normalmente:
  - PIX: recebe na hora
  - TED: pode sacar
  - Cartão: pode usar saldo
  - Pague contas: pode pagar

Clareo NÃO participa do saque da instituição.
```

---

## Checklist MVP

### Semana 1: Setup
- [ ] Configurar Rails + PostgreSQL + Redis
- [ ] Migration: users, institutions, donations, donation_splits
- [ ] Migration: campaigns, posts, post_attachments
- [ ] Migration: subscriptions, donation_reports
- [ ] Auth: JWT encode/decode, login, register
- [ ] Configurar Asaas sandbox

### Semana 2: Services Core
- [ ] AsaasService: create_customer, create_subaccount
- [ ] AsaasService: create_payment (com splits)
- [ ] DonationService: create, confirm
- [ ] Webhook handler: PAYMENT_RECEIVED, PAYMENT_SPLIT_DONE

### Semana 3: Controllers Core
- [ ] InstitutionsController: create, index, show
- [ ] DonationsController: create, show, index
- [ ] WebhooksController: asaas
- [ ] RSpec: testes de service (mock)

### Semana 4: Campanhas + Transparência
- [ ] CampaignService: create, update, close
- [ ] PostService: create, update, delete
- [ ] CampaignsController: CRUD
- [ ] PostsController: CRUD + feed público

### Semana 5: Assinatura + Financeiro
- [ ] SubscriptionService: upgrade, cancel
- [ ] FinanceService: balance, transactions
- [ ] SubscriptionController: upgrade, cancel, invoices
- [ ] FinanceController: balance, transactions, summary

### Semana 6: Relatórios
- [ ] ReportService: generate, download
- [ ] ReportsController: create, list, download
- [ ] Relatório PDF/CSV com resumo

### Semana 7: Teste + Deploy
- [ ] Teste end-to-end com sandbox Asaas
- [ ] Deploy staging
- [ ] Deploy produção
