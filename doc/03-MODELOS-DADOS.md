# Clareo — Modelos de Dados

> 9 tabelas. `donations`, `donation_splits` e `payouts` são o espelho local do
> que o Asaas registra, e existem para reconciliação.

## Tabela: `users`

Quem autentica. Um usuário administra de 1 a N instituições.

```sql
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  password_digest VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  role VARCHAR(30) NOT NULL DEFAULT 'donor',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT users_role_check
    CHECK (role IN ('donor', 'institution_admin', 'platform_admin'))
);

CREATE UNIQUE INDEX idx_users_email ON users (LOWER(email));
CREATE INDEX idx_users_role ON users (role);
```

## Tabela: `institutions`

Entidade de negócio. Separada de `users` porque tem CNPJ, endereço, estratégia
de liquidação e vínculo com o provedor — nada disso é sobre login.

```sql
CREATE TABLE institutions (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  legal_name VARCHAR(255) NOT NULL,
  trade_name VARCHAR(255),

  -- Estratégia de liquidação, imutável após o cadastro
  settlement_strategy VARCHAR(30) NOT NULL,
  CONSTRAINT institutions_strategy_check
    CHECK (settlement_strategy IN ('subaccount', 'pix_payout')),

  -- Exigidos quando settlement_strategy = 'subaccount'
  cnpj VARCHAR(14),
  legal_entity_kind VARCHAR(30),
  declared_monthly_revenue DECIMAL(15, 2),
  contact_email VARCHAR(255),
  mobile_phone VARCHAR(20),
  address_street VARCHAR(255),
  address_number VARCHAR(20),
  address_complement VARCHAR(255),
  address_neighborhood VARCHAR(255),
  address_postal_code VARCHAR(9),
  address_city VARCHAR(120),

  -- Exigido quando settlement_strategy = 'pix_payout'
  pix_key VARCHAR(255),

  -- Vínculo com o provedor, preenchido após o onboarding
  asaas_account_id VARCHAR(64),
  asaas_wallet_id VARCHAR(64),
  registration_status VARCHAR(20) NOT NULL DEFAULT 'unregistered',
  CONSTRAINT institutions_registration_check
    CHECK (registration_status IN ('unregistered', 'pending', 'approved', 'rejected')),

  status VARCHAR(30) NOT NULL DEFAULT 'draft',
  CONSTRAINT institutions_status_check
    CHECK (status IN ('draft', 'pending_approval', 'active', 'blocked')),

  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

  -- O provedor só aceita PJ, e CNPJ é único no sistema inteiro
  CONSTRAINT institutions_cnpj_unique UNIQUE (cnpj)
);

CREATE INDEX idx_institutions_user_id ON institutions (user_id);
CREATE INDEX idx_institutions_wallet_id ON institutions (asaas_wallet_id);
CREATE INDEX idx_institutions_strategy ON institutions (settlement_strategy);
CREATE INDEX idx_institutions_status ON institutions (status);
```

## Tabela: `plans`

Catálogo de planos. `max_institutions` nulo significa ilimitado.

```sql
CREATE TABLE plans (
  id BIGSERIAL PRIMARY KEY,
  code VARCHAR(30) NOT NULL,
  name VARCHAR(60) NOT NULL,
  price_brl DECIMAL(10, 2) NOT NULL DEFAULT 0,
  max_institutions INTEGER,
  features JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT plans_code_check CHECK (code IN ('free', 'pro', 'enterprise')),
  CONSTRAINT plans_max_institutions_check
    CHECK (max_institutions IS NULL OR max_institutions > 0),
  CONSTRAINT plans_price_check CHECK (price_brl >= 0),
  CONSTRAINT plans_code_unique UNIQUE (code)
);
```

## Tabela: `subscriptions`

Uma assinatura ativa por usuário. O índice parcial abaixo é o que garante isso
no banco — a regra não pode depender só da aplicação.

```sql
CREATE TABLE subscriptions (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan_id BIGINT NOT NULL REFERENCES plans(id),
  asaas_subscription_id VARCHAR(64),
  status VARCHAR(20) NOT NULL DEFAULT 'active',
  CONSTRAINT subscriptions_status_check
    CHECK (status IN ('active', 'past_due', 'cancelled', 'expired')),
  current_period_ends_at TIMESTAMP,
  cancelled_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_subscriptions_one_active_per_user
  ON subscriptions (user_id) WHERE status = 'active';
CREATE INDEX idx_subscriptions_plan_id ON subscriptions (plan_id);
CREATE INDEX idx_subscriptions_asaas_id ON subscriptions (asaas_subscription_id);
```

## Tabela: `donations`

Uma doação. `reference` é a chave de idempotência: o provedor aceita
clientes duplicados e cria cobranças duplicadas sem reclamar.

```sql
CREATE TABLE donations (
  id BIGSERIAL PRIMARY KEY,
  institution_id BIGINT NOT NULL REFERENCES institutions(id),

  donor_name VARCHAR(255) NOT NULL,
  donor_email VARCHAR(255),

  amount_brl DECIMAL(15, 2) NOT NULL,
  payment_method VARCHAR(20) NOT NULL,
  CONSTRAINT donations_payment_method_check
    CHECK (payment_method IN ('pix', 'boleto', 'credit_card')),

  status VARCHAR(30) NOT NULL DEFAULT 'pending',
  CONSTRAINT donations_status_check
    CHECK (status IN ('pending', 'received', 'refunded',
                      'cancelled', 'rejected', 'split_blocked')),

  reference VARCHAR(50) NOT NULL,
  asaas_payment_id VARCHAR(64),
  asaas_customer_id VARCHAR(64),

  -- Preenchido no webhook, nunca antes: só o provedor sabe a taxa aplicada
  net_amount_brl DECIMAL(15, 2),
  received_at TIMESTAMP,
  refunded_at TIMESTAMP,

  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

  CONSTRAINT donations_amount_positive CHECK (amount_brl > 0),
  CONSTRAINT donations_reference_unique UNIQUE (reference),
  CONSTRAINT donations_net_amount_check
    CHECK (net_amount_brl IS NULL OR net_amount_brl >= 0)
);

CREATE INDEX idx_donations_institution_id ON donations (institution_id);
CREATE INDEX idx_donations_status ON donations (status);
CREATE INDEX idx_donations_donor_email ON donations (donor_email);
CREATE INDEX idx_donations_asaas_payment_id ON donations (asaas_payment_id);
CREATE INDEX idx_donations_created_at ON donations (created_at);
```

## Tabela: `donation_splits`

Uma linha perna do rateio. Tabela própria, não JSONB, porque é registro
contábil e precisa ser reconciliada com o provedor.

```sql
CREATE TABLE donation_splits (
  id BIGSERIAL PRIMARY KEY,
  donation_id BIGINT NOT NULL REFERENCES donations(id) ON DELETE CASCADE,
  institution_id BIGINT REFERENCES institutions(id),

  recipient VARCHAR(20) NOT NULL,
  CONSTRAINT donation_splits_recipient_check
    CHECK (recipient IN ('institution', 'platform')),

  percentage DECIMAL(7, 4) NOT NULL,
  CONSTRAINT donation_splits_percentage_check
    CHECK (percentage > 0 AND percentage <= 100),

  status VARCHAR(20) NOT NULL DEFAULT 'pending',
  CONSTRAINT donation_splits_status_check
    CHECK (status IN ('pending', 'done', 'cancelled', 'blocked')),

  -- Preenchido no webhook PAYMENT_SPLIT_DONE
  total_value_brl DECIMAL(15, 2),
  asaas_split_id VARCHAR(64),
  cancellation_reason VARCHAR(60),

  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

  -- A perna da instituição aponta para a instituição; a da plataforma não tem
  CONSTRAINT donation_splits_recipient_institution
    CHECK (
      (recipient = 'institution' AND institution_id IS NOT NULL) OR
      (recipient = 'platform' AND institution_id IS NULL)
    )
);

CREATE INDEX idx_donation_splits_donation_id ON donation_splits (donation_id);
CREATE INDEX idx_donation_splits_institution_id ON donation_splits (institution_id);
CREATE INDEX idx_donation_splits_status ON donation_splits (status);
```

## Tabela: `payouts`

Repasse por Pix. Só existe no caminho `:pix_payout` — no caminho `:subaccount`
a instituição saca direto da própria subconta e o Clareo não intermediia.

```sql
CREATE TABLE payouts (
  id BIGSERIAL PRIMARY KEY,
  institution_id BIGINT NOT NULL REFERENCES institutions(id),
  donation_id BIGINT REFERENCES donations(id),

  amount_brl DECIMAL(15, 2) NOT NULL,
  pix_key VARCHAR(255) NOT NULL,
  provider_transfer_id VARCHAR(64),

  status VARCHAR(20) NOT NULL DEFAULT 'pending',
  CONSTRAINT payouts_status_check
    CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),

  failure_reason TEXT,
  completed_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

  CONSTRAINT payouts_amount_positive CHECK (amount_brl > 0)
);

CREATE INDEX idx_payouts_institution_id ON payouts (institution_id);
CREATE INDEX idx_payouts_status ON payouts (status);
CREATE INDEX idx_payouts_donation_id ON payouts (donation_id);
```

### Uma Instituição Pode Receber Vários Payouts da Mesma Doação?

Um payout por `(donation_id, institution_id)`. Sem o índice único abaixo, um
retry de job poderia pagar a instituição duas vezes — o caso mais caro de errar
num produto que movimenta dinheiro de terceiros.

```sql
CREATE UNIQUE INDEX idx_payouts_one_per_donation
  ON payouts (donation_id, institution_id)
  WHERE donation_id IS NOT NULL;
```

## Tabela: `webhook_events`

O provedor entrega **at least once**. Esta tabela é o que torna isso inofensivo:
o `provider_event_id` é a chave de idempotência e o índice único abaixo faz o
duplicado ser fisicamente impossível, não apenas improvável.

```sql
CREATE TABLE webhook_events (
  id BIGSERIAL PRIMARY KEY,
  provider_event_id VARCHAR(128) NOT NULL,
  provider VARCHAR(20) NOT NULL DEFAULT 'asaas',
  event VARCHAR(80) NOT NULL,
  resource_type VARCHAR(30),
  resource_id VARCHAR(64),
  payload JSONB NOT NULL,

  status VARCHAR(20) NOT NULL DEFAULT 'received',
  CONSTRAINT webhook_events_status_check
    CHECK (status IN ('received', 'processing', 'processed', 'failed')),

  attempts INTEGER NOT NULL DEFAULT 0,
  processed_at TIMESTAMP,
  error_message TEXT,

  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

  CONSTRAINT webhook_events_provider_event_unique UNIQUE (provider_event_id)
);

CREATE INDEX idx_webhook_events_status ON webhook_events (status);
CREATE INDEX idx_webhook_events_resource ON webhook_events (resource_type, resource_id);
CREATE INDEX idx_webhook_events_created_at ON webhook_events (created_at);
```

## Tabela: `audit_logs`

```sql
CREATE TABLE audit_logs (
  id BIGSERIAL PRIMARY KEY,
  action VARCHAR(30) NOT NULL,
  entity_type VARCHAR(50) NOT NULL,
  entity_id BIGINT,
  metadata JSONB,
  ip_address VARCHAR(45),
  user_id BIGINT REFERENCES users(id),
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_entity ON audit_logs (entity_type, entity_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs (user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs (created_at);
```

## Relacionamentos

```
users ──┬── institutions (1:N)
        └── subscriptions (1:N, uma ativa)

subscriptions ── plans (N:1)

institutions ──┬── donations (1:N)
               ├── donation_splits (1:N)
               └── payouts (1:N)

donations ──┬── donation_splits (1:N)
            └── payouts (0:1)
```

## Tabelas que Não Existem Mais

| Tabela | Substituída por |
|--------|-----------------|
| `wallets` | `institutions.asaas_wallet_id` — chave Pix do Asaas, não uma blockchain |
| `yield_snapshots` | removida junto com o modelo de yield |
| `wallet_transactions` | `donations` + `payouts` |

## Notas de Schema

**Dinheiro é `DECIMAL`, nunca `FLOAT`.** O domínio usa `BigDecimal` com escala 2
(`Money`); o banco espelha. Dinheiro em ponto flutuante acumula erro.

**`donations.net_amount_brl` é nullable e preenchido tarde.** Antes do webhook
não existe: a taxa do provedor é contratual, não prevista. Coluna NOT NULL com
valor estimado seria mentira contábil.

**Colunas do provedor são `asaas_*`, não genéricas.** A porta `PaymentGateway`
permite trocar o provedor, mas o espelho no banco assume Asaas. Se um dia
trocar, o custo é uma migração — assumido conscientemente.

**`donation_splits.total_value_brl` só existe após o recebimento.** O split
percentual é aplicado sobre o líquido, e o líquido só é conhecido no webhook.

## Migrações

```bash
rails generate migration CreateUsers email:string password_digest:string name:string role:string
rails generate migration CreateInstitutions user_id:integer \
  legal_name:string trade_name:string settlement_strategy:string \
  cnpj:string legal_entity_kind:string declared_monthly_revenue:decimal \
  contact_email:string mobile_phone:string \
  address_street:string address_number:string address_complement:string \
  address_neighborhood:string address_postal_code:string address_city:string \
  pix_key:string asaas_account_id:string asaas_wallet_id:string \
  registration_status:string status:string

rails generate migration CreatePlans code:string name:string \
  price_brl:decimal max_institutions:integer features:jsonb

rails generate migration CreateSubscriptions user_id:integer plan_id:integer \
  asaas_subscription_id:string status:string current_period_ends_at:datetime \
  cancelled_at:datetime

rails generate migration CreateDonations institution_id:integer \
  donor_name:string donor_email:string amount_brl:decimal payment_method:string \
  status:string reference:string asaas_payment_id:string asaas_customer_id:string \
  net_amount_brl:decimal received_at:datetime refunded_at:datetime

rails generate migration CreateDonationSplits donation_id:integer \
  institution_id:integer recipient:string percentage:decimal status:string \
  total_value_brl:decimal asaas_split_id:string cancellation_reason:string

rails generate migration CreatePayouts institution_id:integer donation_id:integer \
  amount_brl:decimal pix_key:string provider_transfer_id:string status:string \
  failure_reason:text completed_at:datetime

rails generate migration CreateWebhookEvents provider_event_id:string provider:string \
  event:string resource_type:string resource_id:string payload:jsonb \
  status:string attempts:integer processed_at:datetime error_message:text

rails generate migration CreateAuditLogs action:string entity_type:string \
  entity_id:integer metadata:jsonb ip_address:string user_id:integer
```

As constraints e índices parciais devem ser adicionados em migrations separadas
ou ao final das migrations de criação — o gerador não os produz.