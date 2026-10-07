# Clareo — Deploy e Infraestrutura

## Restrição de Plataforma

**O projeto não roda no Windows.** O servidor [agoo](https://github.com/ohler55/agoo)
é Linux e macOS only, e é gem nativa — não compila no Windows.

Desenvolvimento local em **WSL (Ubuntu)**:

```bash
# Dentro do WSL
ruby -v                       # 3.2.3 ou superior (Rails 8.1 exige >= 3.2)
bundle install
bundle exec rspec
bin/dev
```

O `Gemfile` não é instalável no Windows. Se aparecer erro de plataforma no
`bundle install`, você está no lugar errado.

## Stack de Deploy

```
Internet
   │  TLS + HTTP/2
   ▼
Thruster ──► Agoo ──► Rails 8.1 API
                 │
                 ├──► PostgreSQL 16
                 ├──► Redis 7 (Sidekiq)
                 └──► Asaas API v3
```

**Thruster** termina TLS e serve HTTP/2. **Agoo** serve a aplicação Rack. Agoo
não termina TLS, então o Thruster fica obrigatoriamente na frente em produção.

## Docker

### Dockerfile

Já configurado:

```dockerfile
FROM docker.io/library/ruby:4.0.6-slim AS base
WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install --no-recommends -y curl libjemalloc2 postgresql-client && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so"
```

Imagem final — **Thruster na frente, Agoo servindo**:

```dockerfile
EXPOSE 80
CMD ["./bin/thrust", "./bin/rackup", "-s", "agoo", "-o", "0.0.0.0", "-p", "3000"]
```

O `rackup` gem entra no `Gemfile` só para isso — Rails 8 não gera o binstub, e o
Thruster precisa de um para iniciar o Agoo.

### Dockerfile.dev

```dockerfile
FROM docker.io/library/ruby:4.0.6-slim
WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install --no-recommends -y build-essential git libpq-dev libyaml-dev \
      postgresql-client redis-tools curl && \
    rm -rf /var/lib/apt/lists

ENV BUNDLE_PATH="/usr/local/bundle"

COPY Gemfile Gemfile.lock ./
RUN bundle install && rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache

COPY . .

EXPOSE 3000
CMD ["bin/dev"]
```

## Docker Compose

```yaml
services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: clareo_development
      POSTGRES_USER: clareo
      POSTGRES_PASSWORD: ${DATABASE_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U clareo"]
      interval: 5s
      timeout: 5s
      retries: 10

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 10

  api:
    build: .
    command: ./bin/thrust ./bin/rackup -s agoo -o 0.0.0.0 -p 3000
    volumes:
      - .:/rails
      - bundle_cache:/usr/local/bundle
    ports:
      - "3000:3000"
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    environment:
      DATABASE_URL: postgresql://clareo:${DATABASE_PASSWORD}@db:5432/clareo_development
      REDIS_URL: redis://redis:6379/0
      RAILS_ENV: development
      ASAAS_API_KEY: ${ASAAS_API_KEY}
      ASAAS_ENVIRONMENT: ${ASAAS_ENVIRONMENT}
      ASAAS_WEBHOOK_URL: ${ASAAS_WEBHOOK_URL}
      ASAAS_WEBHOOK_TOKEN: ${ASAAS_WEBHOOK_TOKEN}

  worker:
    build: .
    command: bundle exec sidekiq -C config/sidekiq.yml
    volumes:
      - .:/rails
      - bundle_cache:/usr/local/bundle
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    environment:
      DATABASE_URL: postgresql://clareo:${DATABASE_PASSWORD}@db:5432/clareo_development
      REDIS_URL: redis://redis:6379/0
      RAILS_ENV: development
      ASAAS_API_KEY: ${ASAAS_API_KEY}
      ASAAS_ENVIRONMENT: ${ASAAS_ENVIRONMENT}

volumes:
  postgres_data:
  redis_data:
  bundle_cache:
```

> Não há mais `tron_sidecar`. TronWeb era dependência do modelo de stablecoin,
> removido. Ver [\_arquivados/README.md](_arquivados/README.md).

## Desenvolvimento Local

```bash
# 1. Dependências
bundle install
cp .env.example .env

# 2. Banco e cache
docker compose up -d db redis

# 3. Schema
bin/rails db:create db:prepare

# 4. Subir API e worker
bin/dev
```

`Procfile.dev`:

```
web: bin/rails server -u agoo -b 0.0.0.0 -p 3000
worker: bundle exec sidekiq
```

O `-u agoo` é obrigatório — sem ele o Rails assume Puma, que não está no
`Gemfile`.

## Variáveis de Ambiente

```bash
# .env.example

# Database
DATABASE_USERNAME=
DATABASE_PASSWORD=
DATABASE_HOST=localhost

# Redis
REDIS_URL=redis://localhost:6379/0

# Rails
RAILS_ENV=development
SECRET_KEY_BASE=
RAILS_MASTER_KEY=

# JWT
JWT_SECRET=
JWT_EXPIRATION=86400

# Asaas
ASAAS_API_KEY=
ASAAS_ENVIRONMENT=sandbox
ASAAS_WEBHOOK_URL=https://api.clareo.com.br/api/v1/webhooks/asaas
ASAAS_WEBHOOK_TOKEN=

# App
FRONTEND_URL=http://localhost:3001
```

### Sobre `ASAAS_ENVIRONMENT`

Nunca inferir o ambiente pela URL da API key. Chave de sandbox em produção é o
erro mais caro possível aqui — a API key errada devolve 401, o que é bom. O
perigo real é o oposto: rodar em produção com `sandbox` silenciosamente aceito.

Variável explícita, valor validado no boot:

```ruby
# config/initializers/asaas.rb
Rails.application.config.after_initialize do
  valid = %w[sandbox production]
  env = ENV.fetch("ASAAS_ENVIRONMENT")

  raise "ASAAS_ENVIRONMENT deve ser sandbox ou production" unless valid.include?(env)

  base = env == "production" ? "https://api.asaas.com/v3" : "https://api-sandbox.asaas.com/v3"

  Rails.application.config.x.asaas = ActiveSupport::OrderedOptions.new
  Rails.application.config.x.asaas.base_url = base
  Rails.application.config.x.asaas.webhook_token = ENV.fetch("ASAAS_WEBHOOK_TOKEN")
end
```

## Webhook: Endpoint Público

O Asaas precisa alcançar a aplicação. Em desenvolvimento local:

```bash
# ngrok
ngrok http 3000

# ou Cloudflare Tunnel
cloudflared tunnel --url http://localhost:3000
```

Configurar no painel do Asaas:

- URL: `https://<tunnel>.ngrok.app/api/v1/webhooks/asaas`
- `authToken`: mesmo valor de `ASAAS_WEBHOOK_TOKEN`
- Eventos: `PAYMENT_RECEIVED`, `PAYMENT_SPLIT_DONE`,
  `PAYMENT_SPLIT_DIVERGENCE_BLOCK`, `PAYMENT_SPLIT_DIVERGENCE_BLOCK_FINISHED`,
  `TRANSFER_DONE`, `TRANSFER_FAILED`, `SUBSCRIPTION_*`, `ACCOUNT_STATUS_*`

Configuração de sandbox e produção são **independentes**. Homologar em sandbox
não configura produção.

## Produção com Kamal

O repositório tem `.kamal/` e `config/deploy.yml` configurados.

```bash
kamal setup
kamal deploy
kamal logs -f app
kamal console            # console Rails no servidor
kamal dbc                # console psql
```

### Checklist Antes do Primeiro Deploy

- [ ] `config/master.key` em cofre de segredo, nunca no repositório
- [ ] `ASAAS_ENVIRONMENT=production`
- [ ] `ASAAS_API_KEY` da **conta de produção**
- [ ] `ASAAS_WEBHOOK_TOKEN` forte (32–255 chars), diferente da chave de API
- [ ] URL de webhook em produção configurada no painel do Asaas
- [ ] `SECRET_KEY_BASE` e `JWT_SECRET` gerados, não reaproveitados de dev
- [ ] `force_ssl = true` em `config/environments/production.rb`
- [ ] CORS limitado a `FRONTEND_URL` de produção
- [ ] Backup automático testado **com restauração**
- [ ] Alerta de webhook reprocessado > 5 vezes
- [ ] Alerta de split bloqueado por divergência

## Health Check

```ruby
# config/routes.rb
get "up" => "rails/health#show", as: :rails_health_check
```

`/up` **não toca o banco**. Uma queda de banco não deve tirar a API de load
balancing — mas isso significa que `/up` não detecta queda de banco. Para isso,
o readiness check do Thruster:

```ruby
# config/initializers/clareo.rb — dentro de after_initialize
Rails.application.config.x.clareo.ready = lambda do
  ActiveRecord::Base.connection.execute("SELECT 1")
  true
rescue StandardError
  false
end
```

## Sidekiq

```yaml
# config/sidekiq.yml
:concurrency: 5
:queues:
  - [critical, 3]
  - [webhooks, 2]
  - [default, 1]
```

`webhooks` em fila separada com peso alto: atrasar confirmação de pagamento
atrasa repasse, que é dinheiro de terceiro esperando.

```ruby
# app/jobs/process_asaas_webhook_job.rb
class ProcessAsaasWebhookJob < ApplicationJob
  queue_as :webhooks

  retry_on ActiveRecord::Deadlocked, wait: :polynomially_longer, attempts: 5
  discard_on ActiveRecord::RecordNotFound

  def perform(provider_event_id)
    event = WebhookEvent.find_by!(provider_event_id: provider_event_id)

    # Já processado: não repete o efeito. O provedor entrega at least once.
    return if event.already_processed?

    event.start_processing!
    Asaas::WebhookRouter.new.route(event)
    event.processed!(at: Time.current)
  rescue StandardError => error
    event.failed!(message: error.message)
    raise
  end
end
```

## Backup

```bash
#!/usr/bin/env bash
# script/backup.sh
set -euo pipefail

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups"
RETENTION_DAYS=30

mkdir -p "$BACKUP_DIR"

# Dump do banco
pg_dump "$DATABASE_URL" | gzip > "$BACKUP_DIR/db_$TIMESTAMP.sql.gz"

# Compacta backup antigo
find "$BACKUP_DIR" -name "db_*.sql.gz" -mtime +$RETENTION_DAYS -delete

# Verifica integridade: um backup que nunca foi restaurado não é backup.
if ! gzip -t "$BACKUP_DIR/db_$TIMESTAMP.sql.gz"; then
  echo "backup corrompido: $BACKUP_DIR/db_$TIMESTAMP.sql.gz" >&2
  exit 1
fi
```

```bash
# crontab -e
0 2 * * * /caminho/para/script/backup.sh >> /var/log/clareo-backup.log 2>&1
```

**Teste de restauração mensal.** Um backup nunca restaurado não é backup.

## Logs

```bash
docker compose logs -f api
docker compose logs -f worker

# Filtrar eventos problemáticos
docker compose logs worker | grep -E "PAYMENT_SPLIT_DIVERGENCE|TRANSFER_FAILED"
```

### O Que Nunca Vai para Log

```ruby
# NUNCA
Rails.logger.info("Subconta criada: #{response.body}")  # CONTÉM accessToken.apiKey
Rails.logger.info("Webhook: #{payload.to_json}")          # pode conter dado pessoal

# Sempre
Rails.logger.info("Webhook #{id} recebido: #{event}")
Rails.logger.info("Doação #{id} confirmada, líquido #{net}")
```

Ver [10-SEGURANCA.md](10-SEGURANCA.md).

## Monitoramento

| Métrica | Limite de alerta |
|---------|------------------|
| Eventos de webhook com `status = failed` | > 0 por 15 min |
| `attempts` de um mesmo `provider_event_id` | > 5 |
| Doações `split_blocked` | qualquer uma |
| Instituições em `pending_approval` | > 60 dias |
| Taxa efetiva por método | mudança > 1 p.p. do previsto |

Os dois últimos vêm do período de avaliação regulatória do provedor: 10
subcontas, R$ 2.000 por subconta, 60 dias. Estourar qualquer um desses limites
**bloqueia** criação de subcontas e novas cobranças. Ver
[16-INTEGRACAO-ASAAS.md](16-INTEGRACAO-ASAAS.md).