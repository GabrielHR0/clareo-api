# Clareo — Segurança

## Princípios

1. **Defense in Depth** — Múltiplas camadas de segurança
2. **Least Privilege** — Apenas o necessário
3. **Never Trust User Input** — Valide tudo
4. **Secure by Default** — Configurações seguras por padrão

## Armazenamento de Chaves Privadas

### ❌ Errado

```ruby
# NUNCA faça isso
wallet.update!(private_key: "minha_chave_privada")
```

### ✅ Correto

```ruby
# Usar AES-256-GCM para criptografar
class Wallet < ApplicationRecord
  def private_key
    decrypt_with_master_key(encrypted_private_key)
  end

  def private_key=(key)
    self.encrypted_private_key = encrypt_with_master_key(key)
  end

  private

  def encrypt_with_master_key(key)
    cipher = OpenSSL::Cipher::AES256.new(:GCM)
    cipher.encrypt

    iv = cipher.random_iv
    cipher.key = ENV['MASTER_ENCRYPTION_KEY']

    encrypted = cipher.update(key) + cipher.final
    tag = cipher.auth_tag

    # Armazenar IV + encrypted + tag
    Base64.strict_encode64(iv + encrypted + tag)
  end

  def decrypt_with_master_key(encrypted_data)
    data = Base64.strict_decode64(encrypted_data)

    iv = data[0, 12]
    tag = data[-16, 16]
    encrypted = data[12..-17]

    decipher = OpenSSL::Cipher::AES256.new(:GCM)
    decipher.decrypt

    decipher.key = ENV['MASTER_ENCRYPTION_KEY']
    decipher.iv = iv
    decipher.auth_tag = tag

    decipher.update(encrypted) + decipher.final
  end
end
```

## Variáveis de Ambiente

```bash
# .env.example — NUNCA committar .env real

# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/clareo_production

# JWT
JWT_SECRET=minimo_32_bytes_aleatorios_aqui

# Binance
BINANCE_API_KEY=
BINANCE_API_SECRET=

# TRON
TRON_FULL_HOST=https://api.trongrid.io
TRON_API_KEY=

# NOWPayments
NOWPAYMENTS_API_KEY=
NOWPAYMENTS_IPN_SECRET=

# Encryption
MASTER_ENCRYPTION_KEY=
```

## Rate Limiting

```ruby
# config/initializers/rack_attack.rb

# Limite geral: 20 req/min por IP
Rack::Attack.throttle('requests by ip', limit: 20, period: 1.minute) do |req|
  req.ip unless req.path.start_with?('/assets')
end

# Login: 5 tentativas por 30 segundos
Rack::Attack.throttle('login attempts', limit: 5, period: 30.seconds) do |req|
  if req.path == '/api/v1/auth/login' && req.post?
    req.ip
  end
end

# Doações: 10 por hora por IP
Rack::Attack.throttle('donations by ip', limit: 10, period: 1.hour) do |req|
  if req.path == '/api/v1/donations' && req.post?
    req.ip
  end
end
```

## Validação de Input

```ruby
class Donation < ApplicationRecord
  validates :amount_brl, presence: true,
    numericality: {
      greater_than: 0,
      less_than_or_equal_to: 100_000
    }

  validates :donor_email, presence: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :payment_method, inclusion: {
    in: %w[pix card boleto]
  }
end
```

## CORS

```ruby
# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'https://seusite.com.br'

    resource '/api/*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ['Authorization'],
      max_age: 600
  end
end
```

## Auditoria

```ruby
# app/models/concerns/auditable.rb
module Auditable
  extend ActiveSupport::Concern

  included do
    after_create :log_create
    after_update :log_update
    after_destroy :log_destroy
  end

  private

  def log_create
    log_action('create')
  end

  def log_update
    log_action('update')
  end

  def log_destroy
    log_action('delete')
  end

  def log_action(action)
    AuditLog.create!(
      action: action,
      entity_type: self.class.name,
      entity_id: id,
      metadata: attributes,
      ip_address: Current.ip_address,
      user_id: Current.user_id
    )
  end
end
```

## HTTPS

```ruby
# config/environments/production.rb
config.force_ssl = true
config.ssl_options = {
  hsts: {
    expires: 1.year,
    subdomains: true,
    preload: true
  }
}
```

## Logs de Segurança

```ruby
# Nunca logar dados sensíveis
Rails.logger.info "Login tentativa para: #{user.email}"
Rails.logger.info "Doação criada: #{donation.id}" # NUNCA logar valores

# Logar apenas hashes de transações
Rails.logger.info "TX Hash: #{tx_hash}"
```

## Checklist de Segurança

- [ ] Chaves privadas criptografadas com AES-256-GCM
- [ ] Variáveis de ambiente para todos os secrets
- [ ] Rate limiting configurado
- [ ] HTTPS habilitado
- [ ] CORS restrito
- [ ] Input validado em todos os endpoints
- [ ] Auditoria em ações sensíveis
- [ ] Logs sem dados sensíveis
- [ ] Senhas hasheadas com bcrypt
- [ ] JWT com expiração
- [ ] Webhooks com verificação de assinatura
