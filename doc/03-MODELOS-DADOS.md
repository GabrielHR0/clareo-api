# Clareo — Modelos de Dados

## Schema do Banco de Dados

### Tabela: `users`

```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL DEFAULT 'donor',
  password_digest VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
```

### Tabela: `wallets`

```sql
CREATE TABLE wallets (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  address VARCHAR(255) NOT NULL UNIQUE,
  encrypted_private_key TEXT NOT NULL,
  balance_usdt DECIMAL(20, 6) NOT NULL DEFAULT 0,
  network VARCHAR(50) NOT NULL DEFAULT 'tron',
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_wallets_user_id ON wallets(user_id);
CREATE INDEX idx_wallets_address ON wallets(address);
CREATE INDEX idx_wallets_network ON wallets(network);
```

### Tabela: `donations`

```sql
CREATE TABLE donations (
  id SERIAL PRIMARY KEY,
  donor_name VARCHAR(255) NOT NULL,
  donor_email VARCHAR(255) NOT NULL,
  amount_brl DECIMAL(15, 2) NOT NULL,
  amount_usdt DECIMAL(20, 6) NOT NULL,
  tx_hash VARCHAR(255),
  status VARCHAR(50) NOT NULL DEFAULT 'pending',
  fee_amount DECIMAL(15, 2) NOT NULL DEFAULT 0,
  payment_method VARCHAR(50) NOT NULL,
  nowpayments_id VARCHAR(255),
  wallet_id INTEGER REFERENCES wallets(id),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_donations_status ON donations(status);
CREATE INDEX idx_donations_donor_email ON donations(donor_email);
CREATE INDEX idx_donations_wallet_id ON donations(wallet_id);
CREATE INDEX idx_donations_nowpayments_id ON donations(nowpayments_id);
```

### Tabela: `withdrawals`

```sql
CREATE TABLE withdrawals (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id),
  wallet_id INTEGER NOT NULL REFERENCES wallets(id),
  amount_brl DECIMAL(15, 2) NOT NULL,
  amount_usdt DECIMAL(20, 6) NOT NULL,
  tx_hash VARCHAR(255),
  status VARCHAR(50) NOT NULL DEFAULT 'pending',
  pix_key VARCHAR(255),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_withdrawals_user_id ON withdrawals(user_id);
CREATE INDEX idx_withdrawals_status ON withdrawals(status);
```

### Tabela: `yield_snapshots`

```sql
CREATE TABLE yield_snapshots (
  id SERIAL PRIMARY KEY,
  wallet_id INTEGER NOT NULL REFERENCES wallets(id),
  balance DECIMAL(20, 6) NOT NULL,
  apy DECIMAL(10, 6) NOT NULL,
  earned DECIMAL(20, 6) NOT NULL,
  protocol VARCHAR(50) NOT NULL DEFAULT 'aave',
  recorded_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_yield_snapshots_wallet_id ON yield_snapshots(wallet_id);
CREATE INDEX idx_yield_snapshots_recorded_at ON yield_snapshots(recorded_at);
```

### Tabela: `audit_logs`

```sql
CREATE TABLE audit_logs (
  id SERIAL PRIMARY KEY,
  action VARCHAR(50) NOT NULL,
  entity_type VARCHAR(50) NOT NULL,
  entity_id INTEGER NOT NULL,
  metadata JSONB,
  ip_address VARCHAR(45),
  user_id INTEGER REFERENCES users(id),
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
```

## Relacionamentos

```
users ──┬── wallets (1:N)
        ├── donations (N:N via wallet_id)
        └── withdrawals (1:N)

wallets ──┬── donations (1:N)
          ├── withdrawals (1:N)
          └── yield_snapshots (1:N)
```

## Migrações Rails

```bash
rails generate migration CreateUsers email:string name:string role:string password_digest:string
rails generate migration CreateWallets user_id:integer address:string encrypted_private_key:text balance_usdt:decimal network:string active:boolean
rails generate migration CreateDonations donor_name:string donor_email:string amount_brl:decimal amount_usdt:decimal tx_hash:string status:string fee_amount:decimal payment_method:string nowpayments_id:string wallet_id:integer
rails generate migration CreateWithdrawals user_id:integer wallet_id:integer amount_brl:decimal amount_usdt:decimal tx_hash:string status:string pix_key:string
rails generate migration CreateYieldSnapshots wallet_id:integer balance:decimal apy:decimal earned:decimal protocol:string
rails generate migration CreateAuditLogs action:string entity_type:string entity_id:integer metadata:jsonb ip_address:string user_id:integer
```
