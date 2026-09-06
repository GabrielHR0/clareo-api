# Clareo — Deploy e Infraestrutura

## Docker Compose

```yaml
version: '3.8'

services:
  db:
    image: postgres:16-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: clareo_production
      POSTGRES_USER: clareo
      POSTGRES_PASSWORD: ${DATABASE_PASSWORD}
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"

  api:
    build: .
    command: bundle exec kino -C config/kino.rb
    volumes:
      - .:/app
      - bundle_cache:/usr/local/bundle
    ports:
      - "3000:3000"
    depends_on:
      - db
      - redis
    environment:
      DATABASE_URL: postgresql://clareo:${DATABASE_PASSWORD}@db:5432/clareo_production
      REDIS_URL: redis://redis:6379/0
      RAILS_ENV: production
      RAILS_MASTER_KEY: ${RAILS_MASTER_KEY}

  sidekiq:
    build: .
    command: bundle exec sidekiq
    volumes:
      - .:/app
      - bundle_cache:/usr/local/bundle
    depends_on:
      - db
      - redis
    environment:
      DATABASE_URL: postgresql://clareo:${DATABASE_PASSWORD}@db:5432/clareo_production
      REDIS_URL: redis://redis:6379/0
      RAILS_ENV: production

  tron_sidecar:
    build: ./node_sidecar
    ports:
      - "3001:3001"
    environment:
      TRON_FULL_HOST: ${TRON_FULL_HOST}
      TRON_API_KEY: ${TRON_API_KEY}

volumes:
  postgres_data:
  redis_data:
  bundle_cache:
```

## Configuração do Kino

```ruby
# config/kino.rb
port 3000
workers 4
threads 1
mode :threaded  # Rails ainda não suporta Ractors

# HTTP/2 nativo (habilitado por padrão)
http2 true

# Logging
log_requests true

# Timeouts
request_timeout 30

# Controle e monitoramento
control_bind "127.0.0.1:9293"

# Graceful shutdown
shutdown_timeout 30
```

## Variáveis de Ambiente

```bash
# .env.example

# Rails
RAILS_ENV=production
RAILS_MASTER_KEY=sua_master_key
SECRET_KEY_BASE=sua_secret_key_base

# Database
DATABASE_URL=postgresql://clareo:senha@db:5432/clareo_production
DATABASE_PASSWORD=senha_segura_aqui

# Redis
REDIS_URL=redis://redis:6379/0

# JWT
JWT_SECRET=minimo_32_bytes_aleatorios

# Binance
BINANCE_API_KEY=
BINANCE_API_SECRET=

# TRON
TRON_FULL_HOST=https://api.trongrid.io
TRON_API_KEY=
TRON_SIDECAR_URL=http://tron_sidecar:3001

# NOWPayments
NOWPAYMENTS_API_KEY=
NOWPAYMENTS_IPN_SECRET=

# Encryption
MASTER_ENCRYPTION_KEY=

# App
APP_URL=https://api.clareo.com.br
FRONTEND_URL=https://clareo.com.br
```

## Deploy com Docker

```bash
# 1. Clonar repositório
git clone https://github.com/seu-usuario/clareo.git
cd clareo

# 2. Configurar variáveis de ambiente
cp .env.example .env

# 3. Build e iniciar
docker-compose up -d

# 4. Rodar migrações
docker-compose exec api rails db:create db:migrate

# 5. Verificar status
docker-compose ps
docker-compose logs -f api
```

## Nginx Reverse Proxy

```nginx
server {
    listen 80;
    server_name api.clareo.com.br;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.clareo.com.br;

    ssl_certificate /etc/letsencrypt/live/api.clareo.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.clareo.com.br/privkey.pem;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## SSL com Let's Encrypt

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d api.clareo.com.br
```

## Health Check

```ruby
# config/routes.rb
get '/health', to: proc { [200, {}, ['OK']] }
```

## Backup

```bash
#!/bin/bash
# backup.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups"

docker-compose exec -T db pg_dump -U clareo clareo_production | gzip > $BACKUP_DIR/db_$DATE.sql.gz

find $BACKUP_DIR -name "*.gz" -mtime +30 -delete
```

### Cron Job

```bash
0 2 * * * /path/to/backup.sh
```
