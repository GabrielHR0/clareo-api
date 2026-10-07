# Clareo — Segurança

## Princípios

1. **Defense in Depth** — múltiplas camadas
2. **Least Privilege** — só o necessário
3. **Never Trust User Input** — valide tudo
4. **Secure by Default** — configuração segura sem ação manual
5. **Não ser instituição de pagamento** — a custódia é do Asaas

## A Maior Mudança de Segurança

O modelo anterior fazia o Clareo **custodiar chave privada de TRON**. Isso
significava:

- Segredo operacional de altíssimo impacto
- Exposição regulatória como custodiante de ativo virtual
- Plano de rotação de chave a cada comprometimento

Nada disso existe mais. **O Clareo não guarda dinheiro de terceiros nem chave
de nada.** A custódia é do Asaas, que é instituição de pagamento autorizada
pelo Banco Central (código 461).

O único segredo de terceiro que o Clareo guarda é a **API key da subconta**,
retornada uma única vez na criação. É segredo de integração, não custódia
financeira.

### Onde a API Key da Subconta Deve Ficar

```ruby
# O segredo nunca entra no domain nem no application.
# Fica cifrado em Rails credentials ou num cofre externo,
# decifrado apenas pelo adapter secundário.
Adapters::Secondary::Asaas::SubaccountCredentials.fetch(institution.id)
```

```bash
# config/credentials.yml.enc — via bin/rails credentials:edit
asaas:
  root_api_key: $aact_hmlg_xxx
  subaccounts:
    # uma entrada por subconta, cifrada
```

**Nunca** em log, em resposta de API, ou em serializer. Se a chave for
comprometida, o procedimento é rotacioná-la pelo endpoint de chaves de API do
provedor.

## Variáveis de Ambiente

```bash
# .env.example — NUNCA commitar .env real

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
JWT_SECRET=minimo_32_bytes_aleatorios
JWT_EXPIRATION=86400

# Asaas
ASAAS_API_KEY=
ASAAS_ENVIRONMENT=sandbox
ASAAS_WEBHOOK_URL=
ASAAS_WEBHOOK_TOKEN=          # 32-255 chars, NÃO pode ser uma API key

# Rate limiting do provedor
ASAAS_RATE_LIMIT_PER_MINUTE=
```

Nenhuma delas é opcional em produção. `ASAAS_ENVIRONMENT` explícito evita o
erro mais caro possível: usar chave de sandbox em produção.

## Webhook: Validação Antes de Persistir

O endpoint de webhook é entrada externa. É a única rota sem JWT.

```ruby
# O endpoint só faz três coisas: validar, persistir, responder.
def receive
  token = request.headers["asaas-access-token"]

  # Comparação de tempo constante. String compare com == vaza informação por timing.
  unless WebhookVerifier.new.valid?(token)
    render json: { error: "invalid token" }, status: :unauthorized
    return
  end

  # Dedup no INSERT: o índice único em webhook_events.provider_event_id
  # torna o duplicato fisicamente impossível.
  created = WebhookEventRepository.new.record(
    provider_event_id: params[:id],
    event: params[:event],
    payload: params.to_unsafe_h,
    resource_type: params[:payment] ? "payment" : "transfer",
    resource_id: params.dig(:payment, :id) || params.dig(:transfer, :id)
  )

  head created ? :ok : :ok
  ProcessAsaasWebhookJob.perform_later(params[:id]) if created
end
```

**Três invariantes:**

1. Token inválido não persiste nada e devolve 401
2. Resposta é enviada **antes** do processamento
3. Duplicado devolve 200 sem efeito colateral

O terceiro ponto evita tempestade de reenvio. O segundo evita que a fila do
provedor seja interrompida: **15 falhas consecutivas** param o envio, e o
endpoint precisa ser rápido.

### Sobre HMAC

O provedor autentica webhook com **token estático compartilhado**, não com
assinatura por requisição. Não há corpo assinado para verificar. Isso é mais
fraco que HMAC, então compensa com:

- Token de 32 a 255 caracteres, gerado sem sequência previsível
- `secure_compare`, nunca `==`
- Restrição por IP quando a infraestrutura permitir
- Rate limit no endpoint
- Monitoramento de volume anômalo

## Autorização: Duas Coisas, Não Uma

Token válido **não** implica permissão.

```ruby
class ApplicationController < ActionController::API
  before_action :authenticate_user!

  private

  def authorize_institution_access!(institution)
    return if current_user.platform_admin?
    return if current_user.institution_ids.include?(institution.id)

    render json: { error: "Não autorizado" }, status: :forbidden
  end
end
```

Um `institution_admin` com JWT válido não pode ler a doação de outra
instituição. A checagem é sempre sobre o recurso, não só sobre o token.

Endpoints sensíveis exigem `platform_admin`:

| Endpoint | Por quê |
|----------|---------|
| `GET /donations/:id/payment` | expõe dado do provedor |
| `GET /webhooks/asaas/events` | expõe payload bruto |
| `POST /webhooks/asaas/reprocess` | reexecuta regra de negócio |
| `GET /admin/institutions` | visão cross-instituição |
| `GET /admin/reconciliation` | dado financeiro consolidado |

## Validação de Input

As validações de negócio vivem no **domínio**, não no controller. O controller
valida apenas formato.

```ruby
# app/adapters/primary/api/v1/donations_controller.rb — só formato
def donation_params
  params.require(:donation).permit(
    :institution_id, :donor_name, :donor_email, :amount_brl, :payment_method
  )
end

# app/domain/entities/donation.rb — regra de negócio
def validate_amount!
  raise InvalidDonation, "amount must be positive" unless amount.positive?
end
```

Isso significa que a regra vale igual pela API, por job, ou por script de
console. Uma validação só no controller é uma validação que o job não tem.

### Validações Específicas

| Campo | Validação | Onde |
|-------|-----------|------|
| `cpf_cnpj` | dígitos verificadores de CPF e CNPJ | `CpfCnpj` |
| `postal_code` | exatamente 8 dígitos | `Address` |
| `amount_brl` | positivo; piso vem do `SplitPolicy` | `Donation` + `SplitPolicy` |
| `reference` | 1–50 chars, sem espaço | `ExternalReference` |
| `splits` | soma exatamente 100% | `Donation` |
| `pix_key` | presença e normalização de espaço | `PixKey` |

`PixKey` **não** valida formato além de presença, de propósito. As regras de
chave Pix do Banco Central são complexas e mudam; um validador local
sutilmente errado rejeita chave válida. O provedor é a autoridade.

## Dinheiro

```ruby
# BigDecimal, escala 2. Nunca Float.
Money.brl("100.00")   # => #<Money 100.00 BRL>
```

No banco, `DECIMAL`. Float em dinheiro acumula erro, e erro em dinheiro é
defeito de conciliação.

## Rate Limiting

```ruby
# config/initializers/rack_attack.rb
class Rack::Attack
  # Geral: 60 req/min por IP
  throttle("requests by ip", limit: 60, period: 1.minute) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  # Login: 5 tentativas por 30 segundos. brute force de senha.
  throttle("login attempts", limit: 5, period: 30.seconds) do |req|
    req.ip if req.path == "/api/v1/auth/login" && req.post?
  end

  # Criação de doação: 10/hora por IP. cria cobrança no provedor, que cobra por isso.
  throttle("donation creation by ip", limit: 10, period: 1.hour) do |req|
    req.ip if req.path == "/api/v1/donations" && req.post?
  end

  # Webhook: o provedor manda em rajada. Limite alto e caminho fixo.
  throttle("webhook by ip", limit: 300, period: 1.minute) do |req|
    req.ip if req.path == "/api/v1/webhooks/asaas"
  end
end
```

O limite de webhook é alto de propósito. Barrar o provedor porque houve rajada
corta confirmação de pagamento — e um pagamento não confirmado é dinheiro que
não chega à instituição.

## CORS

```ruby
# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("FRONTEND_URL", "http://localhost:3001")

    resource "/api/*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      expose: [ "Authorization" ],
      max_age: 600
  end
end
```

Origem única, sem wildcard. `expose: Authorization` só é necessário se o
front-end precisar ler a resposta de preflight.

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

Terminação TLS fica no **Thruster**, na frente do Agoo. Ver
[12-DEPLOY.md](12-DEPLOY.md).

## Auditoria

```ruby
# app/adapters/secondary/persistence/records/concerns/auditable.rb
module Auditable
  extend ActiveSupport::Concern

  included do
    after_create  :audit_create
    after_update  :audit_update
    after_destroy :audit_destroy
  end

  private

  def audit_create  = audit("create")
  def audit_update  = audit("update")
  def audit_destroy = audit("delete")

  def audit(action)
    AuditLog.create!(
      action: action,
      entity_type: model_name.name,
      entity_id: id,
      metadata: audit_payload,
      ip_address: Current.ip_address,
      user_id: Current.user_id
    )
  end

  # Nunca logar segredo. Não incluir api_key, nem payload de webhook cru.
  def audit_payload
    attributes.except("encrypted_subaccount_api_key", "payload")
  end
end
```

Ações que **sempre** geram log de auditoria, independentemente do concern:

- criação e alteração de subconta
- emissão e estorno de cobrança
- payout e alteração de chave Pix
- reprocessamento de webhook
- alteração de plano ou assinatura

## Logs

```ruby
# Nunca
Rails.logger.info("Pagamento: #{params.to_json}")     # pode conter dado pessoal
Rails.logger.info("Subconta criada: #{response.body}") # CONTÉM apiKey

# Sempre
Rails.logger.info("Doação #{donation.id} criada, status=#{donation.status}")
Rails.logger.info("Webhook #{event.id} recebido: #{event.event}")
Rails.logger.info("Split da doação #{id} bloqueado por divergência")
```

`filter_parameter_logging.rb` deve cobrir os segredos:

```ruby
Rails.application.config.filter_parameters += %i[
  access_token asaas-access-token apiKey authorization password
  externalReference
]
```

O último é discutível: `externalReference` é dado de negócio necessário em
log de reconciliação, mas em ambiente de teste pode conter dado de doador. Deixa
fora de produção se houver risco.

## Checklist de Segurança

- [ ] Nenhum segredo de custódia financeira no código — o Asaas custodia
- [ ] API key de subconta cifrada em credentials ou cofre
- [ ] `accessToken.apiKey` persistido no mesmo instante da criação
- [ ] `ASAAS_ENVIRONMENT` explícito e correto
- [ ] Webhook com `secure_compare` e sem estado antes de responder
- [ ] Índice único em `webhook_events.provider_event_id`
- [ ] Autorização por recurso, não só por token
- [ ] Rate limiting em auth, doação e webhook
- [ ] CORS com origem única
- [ ] HTTPS forçado com HSTS
- [ ] Auditoria em ação sensível
- [ ] Segredos fora dos logs
- [ ] Senhas com bcrypt
- [ ] JWT com expiração e blacklist
- [ ] `zeitwerk:check` e `rubocop` no CI

## O que Este Produto Não Faz

Registrado para deixar explícito o que **não** precisa ser Auditado porque não
existe:

- Não há chave privada de blockchain
- Não há saldo de cripto
- Não há chave de API de exchange
- Não há transferência para conta de terceiro não vinculado
- Não há saque sem subconta aprovada

A superfície de ataque financeira é drasticamente menor que a do modelo
arquivado.