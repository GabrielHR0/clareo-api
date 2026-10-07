# Clareo

Plataforma SaaS de captação de doações em BRL, com rateio automático via split
e repasse por Pix para as instituições cadastradas.

Documentação completa em [`doc/`](doc/00-INDEX.md).

## O Modelo

```
Doador ──▶ cobrança no Asaas ──▶ split no recebimento
                                     ├── subconta da instituição
                                     └── taxa da plataforma
```

O Clareo não custodia dinheiro. A custódia é do **Asaas**, instituição de
pagamento autorizada pelo Banco Central.

## Stack

| Camada | Tecnologia |
|--------|------------|
| Backend | Ruby 4.0.6 + Rails 8.1.3 (API mode) |
| Arquitetura | Hexagonal (ports & adapters) |
| Web server | Agoo (C) + Thruster (TLS/HTTP2) |
| Banco | PostgreSQL 16+ |
| Cache/Filas | Redis 7 + Sidekiq |
| Pagamentos | Asaas API v3 |
| Testes | RSpec + RuboCop |

## ⚠️ Não Roda no Windows

O [agoo](https://github.com/ohler55/agoo) é gem nativa e existe apenas para
Linux e macOS. Desenvolva em **WSL (Ubuntu)**.

```bash
wsl -d Ubuntu
cd /mnt/c/Users/Gabriel/Documents/projetos/clareo-api
bundle install
```

## Pré-requisitos

- WSL com Ubuntu (Ruby 3.2.3+)
- Docker (PostgreSQL e Redis) — ou instâncias gerenciáveis
- Docker Compose

Rails 8.1 exige Ruby >= 3.2.0. O `.ruby-version` fixa 4.0.6.

## Setup

```bash
cp .env.example .env
# Edite .env com as credenciais

docker compose up -d db redis
bundle install
bin/rails db:create db:prepare
bin/dev
```

## Como Rodar

```bash
bin/dev                       # API na 3000 + Sidekiq
bundle exec rspec             # 147 exemplos, sem banco
bundle exec rubocop           # lint
bundle exec rails zeitwerk:check
```

O servidor precisa ser indicado explicitamente — o Rails assume Puma, que não
está no `Gemfile`:

```bash
bin/rails server -u agoo -b 0.0.0.0 -p 3000
```

## Variáveis de Ambiente

| Variável | Descrição |
|----------|-----------|
| `DATABASE_USERNAME` | Usuário PostgreSQL |
| `DATABASE_PASSWORD` | Senha PostgreSQL |
| `DATABASE_HOST` | Host PostgreSQL |
| `REDIS_URL` | URL do Redis |
| `SECRET_KEY_BASE` | Chave secreta do Rails |
| `RAILS_MASTER_KEY` | Chave dos credentials |
| `JWT_SECRET` | Segredo do JWT, mínimo 32 bytes |
| `JWT_EXPIRATION` | Expiração em segundos, padrão `86400` |
| `ASAAS_API_KEY` | Chave de API do provedor |
| `ASAAS_ENVIRONMENT` | `sandbox` ou `production` |
| `ASAAS_WEBHOOK_URL` | URL pública do endpoint de webhook |
| `ASAAS_WEBHOOK_TOKEN` | Token de 32–255 chars, **não** pode ser uma API key |
| `FRONTEND_URL` | Origem permitida no CORS |

`ASAAS_ENVIRONMENT` é explícito de propósito. Ambiente inferido a partir da
chave é como se usa chave de sandbox em produção.

## Estrutura

```
├── app/
│   ├── domain/           # Ruby puro. Sem Rails, sem provedor, sem banco.
│   │   ├── entities/     # Institution, Donation, DonationSplit, Payout,
│   │   │                 #   WebhookEvent, Plan, Subscription
│   │   ├── value_objects/# Money, Percentage, CpfCnpj, PixKey, Address
│   │   ├── services/     # SplitPolicy, SettlementPlan
│   │   └── errors/
│   ├── application/      # Casos de uso
│   ├── ports/output/     # Interfaces de saída
│   ├── adapters/         # Implementações concretas
│   └── models/           # ActiveRecord: só persistência
├── spec/
│   ├── domain/           # 147 exemplos, sem Rails e sem banco
│   ├── architecture/     # Falha se o domínio vazar dependência
│   └── domain_helper.rb  # Carrega o domínio sem bundler
├── doc/                  # Documentação
├── config/
└── db/
```

## Testes

O domínio é Ruby puro, então os specs rodam sem Rails, sem banco e sem Bundler.
Isso é verificado por `spec/architecture/domain_independence_spec.rb`, que falha
o build se alguém introduzir ActiveRecord, `Time.current` ou vocabulário do
provedor (`asaas`, `walletId`, `netValue`) no domínio.

## Documentação

| Documento | Assunto |
|-----------|---------|
| [01 — Visão Geral](doc/01-VISAO-GERAL.md) | Produto, modelo, regulatório |
| [02 — Arquitetura](doc/02-ARQUITETURA.md) | Hexagonal, camadas, dependências |
| [03 — Modelos de Dados](doc/03-MODELOS-DADOS.md) | As 9 tabelas |
| [04 — Fluxos](doc/04-FLUXOS.md) | Onboarding, doação, split, payout, webhook |
| [16 — Integração Asaas](doc/16-INTEGRACAO-ASAAS.md) | Contrato com o provedor |
| [11 — Custos e Receitas](doc/11-CUSTOS-RECEITAS.md) | A matemática das taxas |
| [15 — Roadmap](doc/15-ROADMAP.md) | Fases e pendências |
| [Arquivados](doc/_arquivados/README.md) | Integrações do modelo anterior |

## Licença

Proprietário.
