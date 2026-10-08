# Clareo — Arquitetura

> Hexagonal (Ports & Adapters). O domínio não conhece Rails, ActiveRecord nem
> o provedor de pagamentos.

## Por que Hexagonal aqui

O Clareo tem três fontes de mudança independentes:

1. **Regras de negócio** — split, Strategies de liquidação, limite de
   instituições por assinatura
2. **Contrato com o Asaas** — endpoints, status, webhooks
3. **Persistência e entrega** — ActiveRecord, HTTP, Sidekiq

Arquitetura em camadas deixaria o ActiveRecord vazar para as regras e o JSON do
Asaas vazar para o domínio. Hexagonal resolve os dois: o core depende de
interfaces próprias, e os adapters traduzem.

## As Camadas

```
┌──────────────────────────────────────────────────────────────────────┐
│                         ADAPTERS PRIMÁRIOS                          │
│  Entradas do sistema: controllers, jobs Sidekiq, webhooks             │
│  Dependem de: application + ports                                    │
├──────────────────────────────────────────────────────────────────────┤
│                          APPLICATION                                 │
│  Casos de uso. Orquestra e transaciona.                             │
│  Dependem de: domain + interfaces de port                            │
├──────────────────────────────────────────────────────────────────────┤
│                            DOMAIN                                    │
│  Entidades, value objects, services, erros.                          │
│  Dependem de: NADA                                                   │
├──────────────────────────────────────────────────────────────────────┤
│                         ADAPTERS SECUNDÁRIOS                         │
│  Saídas do sistema: Asaas HTTP, repositórios ActiveRecord, fakes     │
│  Dependem de: domain + interfaces de port                            │
└──────────────────────────────────────────────────────────────────────┘
```

## Regras de Dependência

| Camada | Pode referenciar | Não pode referenciar |
|--------|------------------|----------------------|
| `domain` | nada | ActiveRecord, ActiveSupport, Asaas, HTTP |
| `application` | `domain`, ports | ActiveRecord, Asaas, HTTP |
| `ports` | nada (só assinaturas) | qualquer implementação |
| `adapters/primary` | `application`, `domain`, ports | — |
| `adapters/secondary` | `domain`, ports | `application` |

Nenhum ciclo é permitido em nenhuma direção.

Essas regras **são verificadas em teste**, não só documentadas — veja
[Testes de Arquitetura](#testes-de-arquitetura).

## Estrutura de Pastas

```
app/
├── domain/                          # Ruby puro. Zero gems, zero Rails.
│   ├── value_objects/
│   │   ├── money.rb                 # BigDecimal escala 2, BRL
│   │   ├── percentage.rb            # BigDecimal escala 4, 0..100
│   │   ├── cpf_cnpj.rb              # valida DV de CPF e CNPJ
│   │   ├── pix_key.rb               # normaliza; não valida formato
│   │   ├── external_reference.rb    # chave de reconciliação
│   │   ├── address.rb               # endereço completo
│   │   ├── charge_snapshot.rb       # retorno de cobrança
│   │   ├── subaccount_snapshot.rb
│   │   ├── transfer_snapshot.rb
│   │   └── subscription_snapshot.rb
│   ├── entities/
│   │   ├── institution.rb           # instituição e sua estratégia
│   │   ├── donation.rb              # doação e seu estado
│   │   ├── donation_split.rb        # uma perna do rateio
│   │   ├── payout.rb                # repasse por Pix
│   │   ├── webhook_event.rb         # idempotência de webhook
│   │   ├── plan.rb                  # plano, sem cota: assinatura e por instituicao
│   │   └── subscription.rb          # 1 por instituicao
│   ├── services/
│   │   ├── split_policy.rb          # tabela de faixas (dado, não código)
│   │   └── settlement_plan.rb       # instituição + valor -> splits
│   └── errors/
│       ├── domain_error.rb
│       ├── invalid_institution.rb
│       ├── invalid_donation.rb
│       ├── invalid_split.rb
│       └── invalid_subscription.rb
│
├── application/                     # Casos de uso (ainda vazio)
│   ├── commands/
│   └── queries/
│
├── ports/output/                    # Interfaces de saída. Só assinaturas.
│   ├── customer_registry.rb
│   ├── payment_gateway.rb
│   ├── account_manager.rb
│   ├── transfer_service.rb
│   ├── subscription_manager.rb
│   ├── webhook_verifier.rb
│   └── repositories/
│       ├── institution_repository.rb
│       ├── donation_repository.rb
│       ├── payout_repository.rb
│       ├── plan_repository.rb
│       ├── subscription_repository.rb
│       └── webhook_event_repository.rb
│
├── adapters/                        # Implementações concretas
│   ├── primary/                     # controllers, serializers, jobs
│   └── secondary/
│       ├── asaas/                   # HTTP client + adapters do provedor
│       ├── persistence/             # AR records + repositories
│       └── fake/                    # in-memory, para teste e dev
│
├── controllers/
├── jobs/
└── models/                          # AR models: só persistência
```

### Os Nomes São Flat de Propósito

`app/domain/entities/donation.rb` define `Donation`, não `Entities::Donation`.
`Money`, `Percentage` e `Donation` são nomes usados o tempo todo nos casos de
uso; encaixá-los em namespace só adicionaria ruído.

Para conseguir isso, `app/domain/*` e `app/ports/output` são registrados como
raízes de autoload próprias em `config/application.rb`. Sem isso o Rails trata
cada `app/*` como raiz e o Zeitwerk geraria `Entities::Donation` e
`Output::PaymentGateway`.

`app/ports/output/repositories/` **não** é raiz, então fica `Repositories::`.

## Composition Root

Um único lugar conhece os dois lados e decide qual implementação entra em qual
port. Nenhum outro arquivo faz isso.

```ruby
# config/initializers/clareo.rb
Rails.application.config.after_initialize do
  Rails.configuration.x.clareo.payment_gateway =
    if Rails.env.production?
      Adapters::Secondary::Asaas::PaymentGateway.new(http_client: http_client)
    else
      Adapters::Secondary::Fake::PaymentGateway.new
    end
end
```

Nenhum adapter é carregado porRequire dinâmico dentro de caso de uso. Casos de
uso recebem os ports por construtor:

```ruby
class CreateDonation
  def initialize(payment_gateway:, donation_repository:, split_policy: SplitPolicy.default)
    @payment_gateway = payment_gateway
    @donation_repository = donation_repository
    @split_policy = split_policy
  end
end
```

## Decisões de Domínio que Vieram do Provedor

Três regras do domínio existem por causa do Asaas. Estão aqui para que ninguém
as "simplifique" e quebre a integração:

**Split só percentual.** `fixedValue` exige conhecer o `netValue` antes do
recebimento, e a taxa do Asaas é contratual — não controlamos. Então
`DonationSplit` só aceita `percentage`, e o domínio declara os 100% de forma
explícita (instituição + plataforma). O adapter **omite** a entrada da
plataforma ao montar o array, porque o provedor rejeita o `walletId` da conta
emitente.

**A soma dos splits é exatamente 100%.** Não "até 100%". Torna o rateio
auditável e impede que alguém esqueça de declarar a taxa em silêncio.

**A resposta da criação da cobrança não confirma pagamento.** O provedor
responde com status pendente e o pagamento pode nunca chegar. O único caminho
para `received` é `Donation#confirm_receipt!`, alimentado por webhook.

**O webhook é gatilho, a API é fonte da verdade.** O job do webhook não confia
no payload para decidir estado: ele dispara e consulta `GET /v3/payments/{id}`.
Isso elimina a dependência do formato do payload, que varia por evento.

**Estratégia de liquidação é imutável.** Trocá-la com dinheiro em jogo não tem
reversão segura. `Institution` não expõe setter para `settlement_strategy`.

## Regras de Carga

O Zeitwerk não respeita ordem de dependência, e o eager load usa ordem de
diretório. Por isso **nenhuma constante é construída a partir de outra constante
definida no app**:

```ruby
# Errado — quebra no eager load
MINIMUM_DONATION = Money.build("50.00")

# Certo — avaliado em tempo de chamada
def default_minimum_donation
  Money.build("50.00")
end
```

`bin/rails zeitwerk:check` valida os nomes. Também deve rodar em CI.

## Testes

### Domínio

O domínio é Ruby puro, então os specs rodam **sem Rails, sem banco e sem
Bundler** via `spec/domain_helper.rb`:

```ruby
require_relative "../../domain_helper"
```

Custa ~0,9 s para 147 exemplos. Isso é o retorno concreto de manter o core
limpo.

### Testes de Arquitetura

`spec/architecture/domain_independence_spec.rb` falha o build se:

- `app/domain` referenciar ActiveRecord, ActiveSupport, `Time.current`,
  `validates`, `belongs_to`
- `app/domain` tiver `require`
- `app/domain` vazar vocabulário do provedor (`asaas`, `walletId`, `netValue`,
  `percentualValue`, `cus_`, `pay_`)
- `app/ports` fizer HTTP
- `app/application` tocar ActiveRecord

A regra do vocabulário é a que mais importa: `netValue` é conceito do Asaas.
No domínio é `net_amount`, decidido por nós e conhecido por nós.

### Ports

Adapters secundários implementam os ports. Para garantir que um fake não
satisfaz um contrato diferente do adapter real, os dois devem passar pelos
mesmos specs de contrato.

## Por que Agoo e não Puma

Agoo é um servidor HTTP escrito em C, compatível com Rack, e entrega mais
throughput e menos latência que Puma. O trade-off é que ele só existe para
Linux e macOS — o projeto não roda no Windows.

Em produção o Thruster fica na frente, terminando TLS e falando HTTP/2, com o
Agoo servindo a aplicação Rack.