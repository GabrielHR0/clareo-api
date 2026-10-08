# Clareo — API Endpoints

```
https://api.clareo.com.br/api/v1
```

## Convenções

Todos os endpoints, exceto login, cadastro e webhook, exigem:

```
Authorization: Bearer <token>
```

Formato de erro, uniforme em toda a API:

```json
{ "error": "Mensagem legível", "code": "identificador_estavel" }
```

Erros de domínio (`InvalidDonation`, `InvalidInstitution`, `InvalidSplit`,
`InvalidSubscription`) mapeiam para `422`. Erro de autenticação, `401` ou `403`.
Recurso inexistente, `404`.

| Código | Uso |
|--------|-----|
| 200 | Sucesso |
| 201 | Criado |
| 400 | Requisição malformada |
| 401 | Não autenticado ou token expirado |
| 403 | Autenticado mas sem permissão, ou webhook com token inválido |
| 404 | Não encontrado |
| 409 | Conflito — cota de instituições excedida, referência duplicada |
| 422 | Regra de domínio violada |
| 429 | Rate limit excedido |
| 500 | Erro interno |

---

## Auth

### POST /auth/login

```json
{ "email": "joao@example.com", "password": "senha123" }
```

**201** / **200**

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "joao@example.com",
    "name": "João Silva",
    "role": "institution_admin"
  }
}
```

**401** — `{" error": "Credenciais inválidas" }`

### POST /auth/register

```json
{
  "email": "novo@exemplo.com",
  "name": "Maria Santos",
  "password": "senha123",
  "password_confirmation": "senha123"
}
```

**201** — mesmo shape do login.

Cria doador por padrão. Para administrador de instituição, criar a instituição
depois e vincular.

### POST /auth/logout

Invalida o token no Redis. **204**.

---

## Institutions

### POST /institutions

Cadastra uma instituição. É o passo 1 do [Fluxo 1](04-FLUXOS.md#fluxo-1-onboarding-de-instituição-com-cnpj).

**Com CNPJ** (caminho `:subaccount`, dispara criação de subconta):

```json
{
  "legal_name": "Instituto Semear",
  "trade_name": "Semear",
  "cnpj": "66625514000140",
  "legal_entity_kind": "ltda",
  "declared_monthly_revenue": "50000.00",
  "contact_email": "financeiro@institutosemear.org",
  "mobile_phone": "11988887777",
  "address": {
    "street": "Rua Fernando Orlandi",
    "number": "544",
    "complement": "Sala 502",
    "neighborhood": "Jardim Pedra Branca",
    "postal_code": "14079-452",
    "city": "Ribeirão Preto"
  }
}
```

`legal_entity_kind` ∈ `mei`, `ltda`, `mei_eire`, `association`. **`association`
cobre ONGs.**

**Sem CNPJ** (caminho `:pix_payout`):

```json
{
  "legal_name": "Criador de Conteudo",
  "pix_key": "financeiro@criador.com"
}
```

**201**

```json
{
  "id": 1,
  "legal_name": "Instituto Semear",
  "settlement_strategy": "subaccount",
  "status": "pending_approval",
  "registration_status": "pending",
  "accepts_donations": false
}
```

**422** — campo obrigatório ausente, CNPJ com dígito verificador inválido, CEP
com tamanho errado, ou `pix_key` ausente no caminho `:pix_payout`.

**409** — `{" error": "Plano permite apenas 1 instituição", "code": "quota_exceeded" }`

### GET /institutions

Lista as instituições do usuário autenticado. Query: `page`, `per_page`.

### GET /institutions/:id

**200**

```json
{
  "id": 1,
  "legal_name": "Instituto Semear",
  "settlement_strategy": "subaccount",
  "status": "active",
  "registration_status": "approved",
  "accepts_donations": true,
  "withdraws_on_its_own": true,
  "commercial_info_expires_on": "2027-05-05"
}
```

`withdraws_on_its_own` diz ao front-end quem faz o saque: a própria instituição
no caminho `:subaccount`, a plataforma no caminho `:pix_payout`.

`commercial_info_expires_on` precisa de alerta — a revisão anual de informação
comercial é exigência regulatória do provedor.

### PATCH /institutions/:id

Atualiza dados de contato e endereço.

**Bloqueado:** `settlement_strategy` e `cnpj`. Trocá-los exige novo onboarding.

---

## Donations

### POST /donations

```json
{
  "institution_id": 1,
  "donor_name": "João Silva",
  "donor_email": "joao@example.com",
  "amount_brl": "100.00",
  "payment_method": "pix"
}
```

`payment_method` ∈ `pix`, `boleto`, `credit_card`.

**201**

```json
{
  "id": 42,
  "reference": "don_1a2b3c",
  "status": "pending",
  "amount_brl": "100.00",
  "payment_method": "pix",
  "splits": [
    { "recipient": "institution", "percentage": "94.0000" },
    { "recipient": "platform", "percentage": "6.0000" }
  ],
  "payment": {
    "invoice_url": "https://www.asaas.com/i/080225913252",
    "bank_slip_url": null
  }
}
```

`status: pending` significa que a cobrança foi criada, **não** que houve
pagamento. Acompanhe pelo webhook.

**422** — instituição não aceita doações, valor abaixo do mínimo da
`SplitPolicy`, splits não somando 100%.

**409** — `reference` duplicada.

### GET /donations/:id

**200**

```json
{
  "id": 42,
  "reference": "don_1a2b3c",
  "status": "received",
  "amount_brl": "100.00",
  "net_amount_brl": "98.01",
  "received_at": "2026-10-15T14:32:00Z",
  "splits": [
    {
      "recipient": "institution",
      "percentage": "94.0000",
      "status": "done",
      "total_value_brl": "92.13"
    },
    {
      "recipient": "platform",
      "percentage": "6.0000",
      "status": "done",
      "total_value_brl": "5.88"
    }
  ]
}
```

`net_amount_brl` e `total_value_brl` só existem depois do recebimento — antes
disso o provedor ainda não aplicou as taxas.

### GET /donations

Lista doações. Query: `institution_id`, `status`, `page`, `per_page`.

`institution_id` é obrigatório para `institution_admin` e
`platform_admin`; doadores veem apenas as próprias.

### GET /donations/:id/payment

Dados da cobrança no provedor, para reconciliação. **Requer
`platform_admin`** — expõe dado do provedor.

---

## Payouts

Só existe no caminho `:pix_payout`. No caminho `:subaccount` a instituição saca
direto da própria subconta e este recurso não se aplica.

### POST /payouts

```json
{ "institution_id": 2, "donation_id": 42 }
```

Com `donation_id`, paga a parcela daquela doação. Sem ele, paga o saldo
pendente acumulado da instituição.

**202**

```json
{
  "id": 7,
  "institution_id": 2,
  "amount_brl": "92.13",
  "pix_key": "financeiro@criador.com",
  "status": "processing"
}
```

**422** — instituição no caminho `:subaccount`, ou sem valor pendente.

**409** — já existe payout para `(donation_id, institution_id)`.

**422** — saldo da conta insuficiente para cobrir a transferência.

### GET /payouts/:id

**200**

```json
{
  "id": 7,
  "status": "completed",
  "amount_brl": "92.13",
  "pix_key": "financeiro@criador.com",
  "completed_at": "2026-10-16T09:15:00Z",
  "failure_reason": null
}
```

### GET /payouts

Query: `institution_id`, `status`, `page`, `per_page`.

### GET /institutions/:id/payoutable

Quanto a instituição tem a receber e ainda não recebeu. Alimenta o botão de
solicitar saque no front-end.

**200**

```json
{ "institution_id": 2, "pending_amount_brl": "271.44", "donations_pending": 3 }
```

---

## Subscriptions

Uma assinatura ativa por usuário. O plano limita a quantidade de instituições,
não a taxa de split.

### GET /plans

**200**

```json
[
  { "code": "free", "name": "Básico", "price_brl": "0.00", "max_institutions": 1 },
  { "code": "pro", "name": "Pro", "price_brl": "97.00", "max_institutions": 5 },
  { "code": "enterprise", "name": "Enterprise", "price_brl": "497.00", "max_institutions": null }
]
```

`max_institutions: null` significa ilimitado.

### GET /subscriptions/current

**200**

```json
{
  "id": 3,
  "plan": { "code": "pro", "name": "Pro", "price_brl": "97.00" },
  "status": "active",
  "institutions_used": 2,
  "institutions_remaining": 3
}
```

### POST /subscriptions

```json
{ "plan_code": "pro" }
```

**201**

**409** — já existe assinatura ativa. Uma por usuário.

### DELETE /subscriptions/:id

Cancela. Instituições existentes continuam operando, mas novas instituições
ficam bloqueadas. **204**.

---

## Webhooks

### POST /webhooks/asaas

Endpoint público, **sem** autenticação JWT. A autenticação é o header
`asaas-access-token`, comparado com o token configurado no painel do provedor.

**Sequência obrigatória:**

```
validar token → persistir → responder 200 → processar em background
```

**200** — recebido e persistido, ou duplicado já persistido.

**401** — token ausente ou inválido. Nada é persistido.

**4xx / 5xx** — o provedor tenta de novo. Após **15 falhas consecutivas** a
fila é interrompida. Por isso o processamento vai para o Sidekiq e a resposta é
imediata.

### GET /webhooks/asaas/events

Eventos recebidos, para operação. **Requer `platform_admin`**.

Query: `status`, `event`, `page`, `per_page`.

```json
{
  "webhook_events": [
    {
      "provider_event_id": "evt_05b708f961d739ea7eba7e4db318f621",
      "event": "PAYMENT_RECEIVED",
      "resource_type": "payment",
      "resource_id": "pay_080225913252",
      "status": "processed",
      "attempts": 1,
      "created_at": "2026-10-15T14:31:58Z"
    }
  ]
}
```

`status: failed` com `attempts: 5` é a fila que precisa de atenção.

### POST /webhooks/asaas/reprocess

Reprocessa um evento com erro. **Requer `platform_admin`.**

```json
{ "webhook_event_id": 88 }
```

Reprocessar revalida o estado atual da entidade antes de agir — um evento antigo
pode encontrar a entidade já atualizada.

**202**

---

## Admin

### GET /admin/institutions

Todas as instituições, qualquer status. **Requer `platform_admin`**.

### GET /admin/reconciliation

Divergências entre estado local e estado do provedor. **Requer
`platform_admin`**.

Aponta doações com `reference` local sem `asaas_payment_id`, splits pendentes há
mais de 48 horas, e instituições em `pending_approval` há mais de 60 dias — o
limite do período de avaliação regulatória.

---

## Health

### GET /up

Sem autenticação. **200** quando a aplicação sobe. **500** caso contrário.

Usado por balanceador e por monitoramento de disponibilidade. Não toca o banco
de dados de propósito: uma queda de banco não deve tirar a API de load
balancing.