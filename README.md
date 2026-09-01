# Clareo

Plataforma de doações com conversão para USDT (TRC-20) e yield via JustLend.

## Pré-requisitos

- Ruby 4.0.6
- PostgreSQL 16+
- Redis 7+

## Setup

```bash
git clone <repo-url>
cd clareo-2
cp .env.example .env
# Edite .env com suas credenciais de banco
bundle install
rails db:create
rails db:migrate
bin/dev
```

## Variáveis de Ambiente

| Variável | Descrição | Exemplo |
|----------|-----------|---------|
| `DATABASE_USERNAME` | Usuário PostgreSQL | `teste` |
| `DATABASE_PASSWORD` | Senha PostgreSQL | `sua_senha` |
| `DATABASE_URL` | URL de conexão | `postgres://user:pass@localhost:5432/clareo_development` |
| `REDIS_URL` | URL Redis | `redis://localhost:6379/0` |
| `SECRET_KEY_BASE` | Chave secreta Rails | Gere com `rails secret` |

## Como rodar

```bash
bin/dev  # Inicia Rails + Sidekiq
```

## Como rodar os testes

```bash
bundle exec rspec
```

## Estrutura do projeto

```
├── app/
│   ├── controllers/   # API endpoints
│   ├── models/        # ActiveRecord models
│   ├── services/      # Lógica de negócio (Binance, TRON, JustLend, etc.)
│   └── jobs/          # Sidekiq jobs
├── config/
│   ├── database.yml   # Config PostgreSQL (via ENV)
│   ├── sidekiq.yml    # Filas Sidekiq
│   └── initializers/
│       └── sidekiq.rb # Conexão Redis
├── doc/               # Documentação do projeto
├── spec/              # Testes RSpec
└── kino.rb            # Configuração do web server Kino
```

## Licença

Proprietário.
