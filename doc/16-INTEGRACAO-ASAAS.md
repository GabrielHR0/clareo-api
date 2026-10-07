# Clareo — Integração Asaas

> Fonte primária: <https://docs.asaas.com>. Qualquer dúvida sobre comportamento
> do provedor, a documentação do Asaas manda.

## Ambiente e Autenticação

| | URL |
|---|---|
| Produção | `https://api.asaas.com/v3` |
| Sandbox | `https://api-sandbox.asaas.com/v3` |
| Painel Sandbox | <https://sandbox.asaas.com> |

Autenticação por API key no header, em toda requisição:

```
access_token: $ASAAS_API_KEY
Content-Type: application/json
```

```bash
# .env
ASAAS_API_KEY=
ASAAS_ENVIRONMENT=sandbox   # sandbox | production
ASAAS_WEBHOOK_URL=https://api.clareo.com.br/api/v1/webhooks/asaas
ASAAS_WEBHOOK_TOKEN=         # 32-255 chars, ex: whsec_...
```

## Endpoints que o Clareo Usa

| Operação | Método e caminho | Porta |
|----------|------------------|-------|
| Criar pagador | `POST /v3/customers` | `CustomerRegistry` |
| Buscar pagador por referência | `GET /v3/customers` | `CustomerRegistry` |
| Criar subconta | `POST /v3/accounts` | `AccountManager` |
| Buscar subconta | `GET /v3/accounts/{id}` | `AccountManager` |
| Listar subcontas | `GET /v3/accounts` | `AccountManager` |
| Criar cobrança | `POST /v3/payments` | `PaymentGateway` |
| Buscar cobrança | `GET /v3/payments/{id}` | `PaymentGateway` |
| Estornar cobrança | `POST /v3/payments/{id}/refund` | `PaymentGateway` |
| Transferência interna | `POST /v3/transfers` | `TransferService` |
| Buscar transferência | `GET /v3/transfers/{id}` | `TransferService` |
| Criar assinatura | `POST /v3/subscriptions` | `SubscriptionManager` |
| Recuperar walletId próprio | `GET /v3/wallets/` | `AccountManager` |

## Criar Pagador

O provedor **exige** um pagador cadastrado antes de qualquer cobrança.

```http
POST /v3/customers
```

```json
{
  "name": "João Silva",
  "cpfCnpj": "24971563792",
  "email": "joao@example.com",
  "mobilePhone": "4799376637",
  "externalReference": "doador_1a2b3c"
}
```

Resposta relevante:

```json
{
  "object": "customer",
  "id": "cus_000005401844",
  "name": "João Silva",
  "cpfCnpj": "24971563792",
  "personType": "FISICA"
}
```

### Duas Armadilhas Reais

**O provedor aceita clientes duplicados.** Não há unicidade. A deduplicação é
nossa, e por isso `CustomerRegistry` tem `find_by_external_reference` e
`find_by_cpf_cnpj` antes de criar. Sem isso, cada tentativa de criação gera um
pagador novo e a doação fica órfã.

**Timeout inconclusivo gera duplicata.** A própria documentação diz para
verificar se o cadastro foi criado antes de repetir a requisição. Por isso o
`externalReference` é obrigatório no nosso lado.

## Criar Subconta

```http
POST /v3/accounts
```

Campos **obrigatórios**: `name`, `email`, `cpfCnpj`, `mobilePhone`,
`incomeValue`, `address`, `addressNumber`, `province`, `postalCode`.

```json
{
  "name": "Instituto Semear",
  "email": "financeiro@institutosemear.org",
  "cpfCnpj": "66625514000140",
  "mobilePhone": "11988887777",
  "companyType": "LIMITED",
  "taxRegime": "NATIONAL_SIMPLE",
  "incomeValue": 50000.00,
  "address": "Rua Fernando Orlandi",
  "addressNumber": "544",
  "province": "Jardim Pedra Branca",
  "postalCode": "14079-452",
  "webhooks": [
    {
      "name": "Clareo",
      "url": "https://api.clareo.com.br/api/v1/webhooks/asaas",
      "email": "suporte@clareo.com.br",
      "enabled": true,
      "interrupted": false,
      "apiVersion": 3,
      "authToken": "whsec_Pxeh17yy3LQbLVpnzz6I1chB7mtzYk5F7pg8bRR80pE",
      "sendType": "SEQUENTIALLY",
      "events": ["PAYMENT_RECEIVED", "PAYMENT_SPLIT_DONE"]
    }
  ]
}
```

### A Chave de API Vem Aninhada

```json
{
  "object": "account",
  "id": "4f468235-cec3-482f-b3d0-348af4c7194",
  "walletId": "c0c1688f-636b-42c0-b6ee-7339182276b7",
  "personType": "JURIDICA",
  "city": 15478,
  "state": "SP",
  "accessToken": {
    "id": "b6bff0c5-38c6-496a-a3a8-105b31d5bcfe",
    "apiKey": "$aact_hmlg_xxxxx"
  },
  "commercialInfoExpiration": {
    "isExpired": false,
    "scheduledDate": "2027-05-05 00:00:00"
  }
}
```

**A chave está em `accessToken.apiKey`, não no topo.** O guia em texto sugere
topo; o schema real é aninhado. Ler `apiKey` do topo grava `nil` silenciosamente.

**`apiKey` é retornada uma única vez.** Não há como recuperá-la depois.
Persistir no mesmo instante em que chega, ou a subconta fica inútil.

**`incomeValue` é obrigatório** e não é um detalhe: é exigência regulatória de
registro. Por isso `Institution#declared_monthly_revenue` é `Money` e obrigatório
na estratégia `:subaccount` — falha no domínio, não com 400 depois.

**`postalCode` precisa ser válido.** O provedor deriva a cidade a partir do CEP
e responde 400 se não encontrar.

**`companyType` aceita `ASSOCIATION`**, que é como ONGs são representadas.
Valores: `MEI`, `LIMITED`, `INDIVIDUAL`, `ASSOCIATION`.

**`taxRegime`**: `MEI`, `NATIONAL_SIMPLE`, `NORMAL_REGIME`, `UNKNOWN`.

### Limitações Não Contornáveis

**Só pessoa jurídica.** pelas Resoluções Conjuntas 16 e 17 do Banco Central,
conta individual (CPF) não cria subconta. Instituições sem CNPJ usam o caminho
`:pix_payout`.

**Período de avaliação regulatória.** A partir da primeira subconta criada via
API: máximo de **10 subcontas**, máximo de **R$ 2.000,00 em cobranças por
subconta**, duração de até **60 dias**. Atingido qualquer um dos limites, a
criação de novas subcontas e novas cobranças é bloqueada até a avaliação
concluir. Isso dimensiona o MVP: o volume inicial precisa caber nesse teto.

**Sandbox: 20 subcontas por dia.**

## Criar Cobrança

```http
POST /v3/payments
```

```json
{
  "customer": "cus_000005401844",
  "billingType": "PIX",
  "value": 100.00,
  "dueDate": "2026-10-15",
  "description": "Doação para Instituto Semear",
  "externalReference": "don_1a2b3c",
  "split": [
    {
      "walletId": "c0c1688f-636b-42c0-b6ee-7339182276b7",
      "percentualValue": 94.0000,
      "externalReference": "don_1a2b3c_institution",
      "description": "Instituto Semear"
    }
  ]
}
```

Resposta relevante:

```json
{
  "object": "payment",
  "id": "pay_080225913252",
  "value": 100.00,
  "netValue": 98.01,
  "status": "PENDING",
  "billingType": "PIX",
  "invoiceUrl": "https://www.asaas.com/i/080225913252",
  "bankSlipUrl": null,
  "split": [
    {
      "id": "fd41396a-7453-47d0-9411-c8543522591d",
      "walletId": "c0c1688f-636b-42c0-b6ee-7339182276b7",
      "status": "PENDING"
    }
  ]
}
```

**`status: PENDING` na criação não é confirmação.** É o estado inicial. Pagamento
pode nunca chegar. Só o webhook move para `RECEIVED`.

### `billingType`

Na criação aceita `UNDEFINED`, `BOLETO`, `CREDIT_CARD`, `PIX`. `DEBIT_CARD`
aparece no enum da resposta mas **não** pode ser criado.

`UNDEFINED` deixa o pagador escolher entre os métodos habilitados — bom para
maximizar conversão, desde que a instituição tenha os métodos ativos na conta.

### Split

| Campo | Tipo | Uso |
|-------|------|-----|
| `walletId` | string | obrigatório; destino da transferência |
| `percentualValue` | number | até 4 casas decimais |
| `fixedValue` | number | até 2 casas; exige conhecer o líquido antes |
| `totalFixedValue` | number | só em parcelamento |
| `externalReference` | string | reconciliação com nosso lado |
| `description` | string | identificação operacional |

**O `walletId` da conta emitente não pode ir no split.** O provedor responde com
exceção. Todo saldo não direcionado permanece automaticamente na conta que
criou a cobrança — é assim que a Clareo fica com a taxa dela sem declarar nada.

Por isso o domínio declara os 100% explicitamente (instituição + plataforma) e o
adapter omite a perna da plataforma. Ver
[02-ARQUITETURA.md](02-ARQUITETURA.md#decisões-de-domínio-que-vieram-do-provedor).

### Todo Split Incide Sobre o Líquido

```
Cobrança R$ 100,00
Taxa do provedor (Pix) R$ 1,99
netValue R$ 98,01

94% → R$ 92,13   vai para a instituição
6%  → R$ 5,88    fica com a Clareo
```

Misturar fixo e percentual não tem prioridade entre si; ambos são validados
contra o líquido disponível.

## Bloqueio por Divergência no Split

Se na hora do recebimento a soma do split ultrapassar o líquido, o provedor
**bloqueia** o valor e o split.

```
R$ 100,00 − R$ 1,99 = R$ 98,01 líquido

Split: fixedValue R$ 50,00 + percentualValue 50%
  50% de R$ 98,01 = R$ 49,00
  R$ 50,00 + R$ 49,00 = R$ 99,00  > R$ 98,01  → inválido
```

Fluxo:

1. Split bloqueado no recebimento ou antecipação
2. Webhook `PAYMENT_SPLIT_DIVERGENCE_BLOCK`
3. **2 dias úteis** para ajustar o split
4. Ajustado dentro do prazo com valor ≤ bloqueado → desbloqueia e processa
5. Sem ajuste → expira, split cancelado, saldo liberado
6. Webhook `PAYMENT_SPLIT_DIVERGENCE_BLOCK_FINISHED`

Com apenas `percentualValue` a soma nunca passa de 100%, então divergência exige
mudança de proporção entre instituições ou taxa da plataforma entre a criação da
cobrança e o recebimento.

### Split em Assinatura Pode Travar a Recorrência

Se o split da **assinatura** divergir, a assinatura inteira pode ser bloqueada e
parar de gerar cobranças:

```
SUBSCRIPTION_SPLIT_DIVERGENCE_BLOCK
SUBSCRIPTION_SPLIT_DIVERGENCE_BLOCK_FINISHED
```

Risco diferente do split em cobrança avulsa: aqui o problema se multiplica por
todas as cobranças futuras. Onde houver assinatura com split, monitorar esses
dois eventos.

## Webhooks

### Autenticação

Header `asaas-access-token`, comparado com o `authToken` configurado no webhook.

É **token estático compartilhado**, não assinatura HMAC por requisição. A
comparação precisa ser de tempo constante (`ActiveSupport::SecurityUtils.secure_compare`).

Regras do token: 32 a 255 caracteres, sem espaços, sem sequências simples, e
**não** pode ser uma API key do Asaas.

### Formato

```json
{
  "id": "evt_05b708f961d739ea7eba7e4db318f621",
  "event": "PAYMENT_RECEIVED",
  "dateCreated": "2026-06-12 16:45:03",
  "payment": {
    "object": "payment",
    "id": "pay_080225913252"
  }
}
```

O objeto relacionado **varia por evento** e no exemplo vem mínimo. Por isso o
job não decide estado pelo payload: ele persiste o evento e consulta
`GET /v3/payments/{id}`. É a postura que a própria documentação do provedor
recomenda.

### Eventos que o Clareo Consome

| Evento | Uso |
|--------|-----|
| `PAYMENT_RECEIVED` | cobrança liquidada — dispara confirmação |
| `PAYMENT_CONFIRMED` | confirmação, antes da liquidação |
| `PAYMENT_UPDATED` | mudança de status |
| `PAYMENT_OVERDUE` | cobrança vencida |
| `PAYMENT_REFUNDED` | estorno, reverte o split automaticamente |
| `PAYMENT_SPLIT_DONE` | split liquidado, com `totalValue` |
| `PAYMENT_SPLIT_CANCELLED` | split cancelado |
| `PAYMENT_SPLIT_DIVERGENCE_BLOCK` | split bloqueado por divergência |
| `PAYMENT_SPLIT_DIVERGENCE_BLOCK_FINISHED` | desbloqueio por expiração |
| `TRANSFER_PENDING` | transferência aguardando conclusão |
| `TRANSFER_DONE` | repasse concluído |
| `TRANSFER_FAILED` | repasse falhou |
| `TRANSFER_CANCELLED` | repasse cancelado |
| `TRANSFER_BLOCKED` | transferência bloqueada |
| `SUBSCRIPTION_CREATED` / `UPDATED` / `INACTIVATED` / `DELETED` | ciclo da assinatura |
| `SUBSCRIPTION_SPLIT_DIVERGENCE_BLOCK` | split da assinatura divergiu |
| `ACCOUNT_STATUS_DOCUMENT_*` | aprovação de documentos da subconta |
| `ACCOUNT_STATUS_BANK_ACCOUNT_INFO_*` | dados bancários da subconta |
| `ACCOUNT_STATUS_COMMERCIAL_INFO_*` | informação comercial da subconta |
| `ACCOUNT_STATUS_GENERAL_APPROVAL_*` | aprovação geral da subconta |
| `BALANCE_VALUE_BLOCKED` / `UNBLOCKED` | bloqueio de saldo |

Os `ACCOUNT_STATUS_*` são o que move `Institution#registration_status` de
`pending` para `approved`.

### Processamento

Fluxo obrigatório, e a ordem importa:

```
receber → validar → persistir → responder 200 → processar
```

- **At least once.** O mesmo `id` chega mais de uma vez. `webhook_events.provider_event_id`
  tem índice único: o duplicado é fisicamente impossível, não apenas improvável.
- **Responder antes de processar.** Depois de 15 falhas consecutivas a fila do
  provedor é **interrompida**. Processar a regra de negócio antes de responder
  arrisca estourar esse limite.
- **Estado interno** de `received` → `processing` → `processed` / `failed`, com
  contador de tentativas, para reprocessar falha com segurança.
- **Reprocessar exige revalidar o estado atual** da entidade. Um evento antigo
  pode chegar depois que atualizações mais novas já escreveram no banco.

## Transferências

```http
POST /v3/transfers
```

Entre contas Asaas vinculadas (interna):

```json
{
  "value": 92.13,
  "walletId": "c0c1688f-636b-42c0-b6ee-7339182276b7",
  "externalReference": "payout_1a2b3c"
}
```

Para chave Pix externa:

```json
{
  "value": 92.13,
  "pixKey": "financeiro@institutosemear.org",
  "externalReference": "payout_1a2b3c"
}
```

**Transferência interna exige vínculo com a conta.** Só funciona entre a conta
principal e subcontas que ela criou. Transferência para Pix de terceiro não tem
essa exigência — é o que o caminho `:pix_payout` usa.

**Limite de Pix para conta nova: R$ 5.000.** Afeta diretamente o caminho
`:pix_payout` no começo da operação.

O split **não** permite agendamento. Executa no recebimento. Para repassar em
data futura, criar a cobrança sem split e fazer transferência interna depois.

## Recuperar o próprio `walletId`

```http
GET /v3/wallets/
```

```json
{
  "object": "list",
  "totalCount": 1,
  "hasMore": false,
  "limit": 10,
  "offset": 0,
  "data": [
    { "object": "wallet", "id": "0000c712-0a0b-a0b0-0000-031e7ac51a2" }
  ]
}
```

Dois detalhes que custam tempo se ignorados: a resposta é uma **lista paginada**,
não um objeto; e um **GET com body preenchido retorna 403**.

O Clareo quase não precisa disso: o `walletId` da conta emitente não pode ir em
split. É útil para reconciliação e auditoria.

## Estorno

Reverter uma cobrança **reverte o split**: todas as contas que receberam
transferência têm o valor devolvido. Não é necessário estornar perna por perna.

Excluir uma cobrança remove a configuração do split. Se a cobrança for restaurada
e paga, o split não existe mais — precisa ser reconfigurado.

Atualizar uma cobrança com `split: null` ou `split: []` **desativa** o split.
Para atualizar sem tocar no split, omitir o parâmetro.

## Erros

Formato:

```json
{
  "errors": [
    { "code": "invalid_customer", "description": "Customer Inválido ou não informado" }
  ]
}
```

| HTTP | Situação |
|------|----------|
| 400 | payload inválido, CEP não encontrado, `incomeValue` faltando, soma de split acima do líquido |
| 401 | API key inválida ou do ambiente errado |
| 403 | `GET` com body; webhook bloqueado por firewall |
| 404 | recurso inexistente |
| 408 / 500 | falha do provedor, retentativa pelo mesmo evento |

O adapter deve traduzir `errors[].code` para exceções de domínio, para que
`application` nunca veja o JSON do provedor.

## Limites de Taxa

Consulte <https://docs.asaas.com/reference/rate-e-quota-limit>. Toda
integração precisa de retry com backoff e controle de concorrência.

## Ainda Não Verificado

Pendências a confirmar antes do go-live, com a documentação relevante:

| Pendência | Onde olhar |
|-----------|-----------|
| Header de idempotência para retry de `POST /v3/payments` | `/docs/retries-e-idempotencia` |
| Payload completo de `PAYMENT_RECEIVED` — se `netValue` e `split[]` vêm no webhook | `/docs/eventos-de-webhooks` |
| Se o provedor assina o webhook além do `asaas-access-token` | `/docs/receba-eventos-do-asaas-no-seu-endpoint-de-webhook` |
| Se há divergência entre 30 e 100 Pix grátis por mês | página de preços vs. central de ajuda |
| Limites exatos de rate limit | `/reference/rate-e-quota-limit` |

## Checklist de Sandbox

- [ ] Conta criada em <https://sandbox.asaas.com>
- [ ] API key de sandbox gerada e configurada
- [ ] Subconta criada e `accessToken.apiKey` persistido
- [ ] `walletId` guardado
- [ ] Cobrança Pix criada com `split` e `externalReference`
- [ ] `PAYMENT_RECEIVED` e `PAYMENT_SPLIT_DONE` recebidos
- [ ] `webhook_events` sem duplicidade sob reenvio forçado do mesmo evento
- [ ] Estorno reverte o split
- [ ] Transferência Pix para chave externa concluída