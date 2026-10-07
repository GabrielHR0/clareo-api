# Clareo — Referências Oficiais

## Pagamentos

| Serviço | URL | Descrição |
|---------|-----|-----------|
| **Documentação Asaas** | <https://docs.asaas.com> | Fonte primária |
| Índice de páginas (LLM) | <https://docs.asaas.com/llms.txt> | Descoberta de endpoints |
| Split — visão geral | <https://docs.asaas.com/docs/split-de-pagamentos> | Conceito de split |
| Split — FAQ | <https://docs.asaas.com/docs/split> | Regras, limites, erros |
| Split em cobrança única | <https://docs.asaas.com/docs/split-in-single-payments> | Payload |
| Split em parcelamentos | <https://docs.asaas.com/docs/split-into-installments> | `totalFixedValue` |
| Split em assinaturas | <https://docs.asaas.com/docs/split-em-assinaturas> | Split como template |
| Subcontas | <https://docs.asaas.com/docs/criacao-de-subcontas> | Fluxo de onboarding |
| Subcontas — FAQ de avaliação | <https://docs.asaas.com/docs/faq-evaluation-period> | Limites dos primeiros 60 dias |
| Subcontas — revisão anual | <https://docs.asaas.com/docs/confirmação-anual-de-dados-comerciais-para-subcontas> | Exigência regulatória |
| Criar subconta | <https://docs.asaas.com/reference/create-subaccount> | `POST /v3/accounts` |
| Criar cobrança | <https://docs.asaas.com/reference/criar-nova-cobranca> | `POST /v3/payments` |
| Criar pagador | <https://docs.asaas.com/reference/criar-novo-cliente> | `POST /v3/customers` |
| Recuperar walletId | <https://docs.asaas.com/reference/recuperar-walletid> | `GET /v3/wallets/` |
| Transferência interna | <https://docs.asaas.com/reference/transferir-para-conta-asaas> | `POST /v3/transfers` |
| Transferência Pix externa | <https://docs.asaas.com/docs/transferencia-para-contas-de-outra-instituicao-pix-ted> | Saque por Pix |
| Webhooks — receber eventos | <https://docs.asaas.com/docs/receba-eventos-do-asaas-no-seu-endpoint-de-webhook> | Autenticação e payload |
| Webhooks — idempotência | <https://docs.asaas.com/docs/como-implementar-idempotencia-em-webhooks> | Chave de dedup |
| Webhooks — eventos | <https://docs.asaas.com/docs/eventos-de-webhooks> | Lista completa |
| Webhooks — fila pausada | <https://docs.asaas.com/docs/fila-pausada> | 15 falhas consecutivas |
| Webhooks — IPs oficiais | <https://docs.asaas.com/docs/ips-oficiais-do-asaas> | Whitelist de origem |
| **Guia de arquitetura de integração** | <https://docs.asaas.com/docs/guia-de-arquitetura-de-integrações> | Estados, retries, reconciliação |
| Webhooks e eventos (guia) | <https://docs.asaas.com/docs/webhooks-e-eventos> | Receber, persistir, processar |
| Retries e idempotência | <https://docs.asaas.com/docs/retries-e-idempotência> | Retry seguro |
| Limites de API | <https://docs.asaas.com/reference/rate-e-quota-limit> | Rate limit |
| **Preços e taxas** | <https://www.asaas.com/precos-e-taxas> | Referência pública |
| Sandbox | <https://sandbox.asaas.com> | Ambiente de teste |
| Central de ajuda | <https://central.ajuda.asaas.com> | Dúvidas operacionais |

## Backend

| Tecnologia | URL | Descrição |
|------------|-----|-----------|
| Ruby | <https://www.ruby-lang.org/en/documentation/> | Linguagem |
| Ruby on Rails | <https://rubyonrails.org/docs> | Framework |
| Rails — API mode | <https://guides.rubyonrails.org/api_applications.html> | Guia de API |
| **Agoo** | <https://github.com/ohler55/agoo> | Servidor HTTP em C. **Linux/macOS only** |
| Agoo — documentação | <https://rubydoc.info/gems/agoo> | Referência da API |
| Rack | <https://github.com/rack/rack> | Interface de servidor web |
| Rackup | <https://github.com/rack/rackup> | Binstub para servir Rack |
| Thruster | <https://github.com/basecamp/thruster> | Proxy TLS/HTTP2 |
| PostgreSQL | <https://www.postgresql.org/docs/> | Banco de dados |
| Redis | <https://redis.io/docs/> | Cache e filas |
| Kamal | <https://kamal-deploy.org> | Deploy de containers |
| Sidekiq | <https://github.com/sidekiq/sidekiq> | Processamento assíncrono |
| Sidekiq — wiki | <https://github.com/sidekiq/sidekiq/wiki> | Configuração |

## Arquitetura

| Tecnologia | URL | Descrição |
|------------|-----|-----------|
| Hexagonal Architecture | <https://alistair.cockburn.us/hexagonal-architecture> | Artigo original |
| RubyDoc — Ports and Adapters | <https://github.com/corlaez/32707a1c41485d056c00251206435c89> | Implementação de referência |
| Solid Process | <https://github.com/solid-process/solid-rails-app> | Progressão até hexagonal em Rails |

## Autenticação e Segurança

| Tecnologia | URL | Descrição |
|------------|-----|-----------|
| JWT Ruby | <https://github.com/jwt/ruby-jwt> | Geração e validação de token |
| BCrypt | <https://github.com/bcrypt-ruby/bcrypt-ruby> | Hash de senha |
| Rack::Attack | <https://github.com/rack/rack-attack> | Rate limiting |

## Serialização e Testes

| Tecnologia | URL | Descrição |
|------------|-----|-----------|
| Alba | <https://github.com/okuramasafumi/alba> | Serialização JSON |
| RSpec | <https://rspec.info> | Framework de teste |
| RuboCop Omakase | <https://github.com/rails/rubocop-rails-omakase> | Padrão de estilo |
| Zeitwerk | <https://github.com/zeitwerk/zeitwerk> | Autoload. `bin/rails zeitwerk:check` |

## Infraestrutura

| Tecnologia | URL | Descrição |
|------------|-----|-----------|
| Docker | <https://docs.docker.com/> | Containerização |
| Docker Compose | <https://docs.docker.com/compose/> | Orquestração local |
| Nginx | <https://nginx.org/en/docs/> | Reverse proxy alternativo |
| Let's Encrypt | <https://letsencrypt.org/docs/> | Certificado TLS |

## Monitoramento

| Tecnologia | URL | Descrição |
|------------|-----|-----------|
| Prometheus | <https://prometheus.io/docs/> | Métricas |
| Grafana | <https://grafana.com/docs/> | Dashboards |
| Sentry | <https://docs.sentry.io/> | Rastreamento de erro |

## Regulatório

| Assunto | URL | Descrição |
|---------|-----|-----------|
| Banco Central — IP | <https://www.bcb.gov.br/estabilidadefinanceira/enpg> | Instituições de pagamento |
| Resolução Conjunta 3.949 | <https://www.bcb.gov.br/estabilidadefinanceira/exibenormativo?tipo=Resolu%C3%A7%C3%A3o%20BC&numero=3949> | BaaS |
| Resolução Conjunta 4.893 | <https://www.bcb.gov.br/estabilidadefinanceira/exibenormativo> | BaaS |

> A exigência de que subcontas só existam para pessoa jurídica vem das Resoluções
> Conjuntas 16 e 17 do Banco Central, citadas na documentação do provedor.
> Confirmar a numeração vigente com o Jurídico antes do go-live.

---

## Por Arquivo

### Produto e Arquitetura

- [01-VISAO-GERAL.md](01-VISAO-GERAL.md) — o produto, o modelo, a posição regulatória
- [02-ARQUITETURA.md](02-ARQUITETURA.md) — hexagonal, camadas, regras de dependência
- [03-MODELOS-DADOS.md](03-MODELOS-DADOS.md) — as 9 tabelas
- [04-FLUXOS.md](04-FLUXOS.md) — onboarding, doação, split, payout, assinatura, webhook

### Integração

- [16-INTEGRACAO-ASAAS.md](16-INTEGRACAO-ASAAS.md) — contrato com o provedor
- [\_arquivados/README.md](_arquivados/README.md) — integrações removidas e por quê

### Operação

- [09-AUTHENTICATION.md](09-AUTHENTICATION.md) — JWT, papéis, autorização
- [10-SEGURANCA.md](10-SEGURANCA.md) — o que mudou e o que auditar
- [11-CUSTOS-RECEITAS.md](11-CUSTOS-RECEITAS.md) — a matemática das taxas
- [12-DEPLOY.md](12-DEPLOY.md) — Docker, WSL, produção
- [13-API-ENDPOINTS.md](13-API-ENDPOINTS.md) — contrato HTTP
- [14-REFERENCIAS.md](14-REFERENCIAS.md) — este documento
- [15-ROADMAP.md](15-ROADMAP.md) — fases e pendências

## Documentos Removidos

Integrações do modelo anterior, arquivadas com a justificativa do descarte:

| Removido | Substituído por |
|----------|------------------|
| `05-INTEGRACAO-BINANCE.md` | Asaas — conversão BRL↔USDT deixou de existir |
| `06-INTEGRACAO-TRON.md` | Asaas — sem USDT TRC-20 |
| `07-INTEGRACAO-JUSTLEND.md` | Asaas — sem yield |
| `08-INTEGRACAO-NOWPAYMENTS.md` | Asaas — provedor único |
| `14-REFERENCIAS.md` seção TRON/Binance | esta seção |

Ver [\_arquivados/README.md](_arquivados/README.md).