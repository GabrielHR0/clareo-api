# Clareo — Fluxos com Asaas Split Payment

## Visão Geral dos Fluxos

```
┌──────────┐     PIX      ┌──────────┐    Split     ┌──────────┐
│  Doador  │ ───────────→ │  Asaas   │ ──────────→ │Instituição│
│          │              │  (PSP)   │ ──────────→ │    A     │
└──────────┘              └──────────┘             └──────────┘
                               │
                               │ Webhook
                               ↓
                        ┌──────────┐
                        │  Clareo  │
                        │  (API)   │
                        └──────────┘
```

---

## Fluxo 1: Cadastro de Doador

```
┌─────────┐                          ┌─────────┐
│  Front  │                          │  Clareo │
└────┬────┘                          └────┬────┘
     │                                     │
     │  POST /api/v1/auth/register        │
     │  { name, email, password }         │
     │ ──────────────────────────────────→│
     │                                     │
     │                                     │  Valida dados
     │                                     │  bcrypt(password)
     │                                     │  Cria User no PG
     │                                     │
     │                                     │  Gera JWT
     │  { token, user }                   │
     │ ←──────────────────────────────────│
```

**Status:** Usuário criado, pronto para doar.

---

## Fluxo 2: Cadastrar Instituição (Admin)

```
┌─────────┐                          ┌─────────┐                          ┌─────────┐
│  Admin  │                          │  Clareo │                          │ Asaas   │
└────┬────┘                          └────┬────┘                          └────┬────┘
     │                                     │                                     │
     │  POST /api/v1/institutions         │                                     │
     │  { name, cnpj, pix_key,           │                                     │
     │    description }                   │                                     │
     │ ──────────────────────────────────→│                                     │
     │                                     │                                     │
     │                                     │  1. Valida dados                   │
     │                                     │                                     │
     │                                     │  2. POST /customers                │
     │                                     │  { name, cpfCnpj, email }          │
     │                                     │  ─────────────────────────────────→│
     │                                     │                                     │
     │                                     │  ← { id: "cus_abc123" }            │
     │                                     │  ←─────────────────────────────────│
     │                                     │                                     │
     │                                     │  3. POST /subaccounts              │
     │                                     │  { name, cpfCnpj, email }          │
     │                                     │  ─────────────────────────────────→│
     │                                     │                                     │
     │                                     │  ← { id: "sub_xyz789",             │
     │                                     │      walletId: "wallet_123" }      │
     │                                     │  ←─────────────────────────────────│
     │                                     │                                     │
     │                                     │  4. Salva Institution              │
     │                                     │     asaas_customer_id = cus_abc123 │
     │                                     │     asaas_wallet_id = wallet_123   │
     │                                     │                                     │
     │  { institution }                    │                                     │
     │ ←──────────────────────────────────│                                     │
```

**Status:** Instituição criada com subconta Asaas, pronta para receber splits.

---

## Fluxo 3: Criar Doação

### 3.1 Doador Inicia Doação

```
┌─────────┐                          ┌─────────┐                          ┌─────────┐
│  Doador │                          │  Clareo │                          │ Asaas   │
└────┬────┘                          └────┬────┘                          └────┬────┘
     │                                     │                                     │
     │  POST /api/v1/donations            │                                     │
     │  Authorization: Bearer <jwt>       │                                     │
     │  {                                 │                                     │
     │    amount_brl: 100.00,             │                                     │
     │    institution_ids: [1, 2]         │                                     │
     │  }                                 │                                     │
     │ ──────────────────────────────────→│                                     │
     │                                     │                                     │
     │                                     │  1. Valida JWT + dados             │
     │                                     │                                     │
     │                                     │  2. Busca instituições             │
     │                                     │     Institution.where(id: [1,2])   │
     │                                     │                                     │
     │                                     │  3. Calcula splits                 │
     │                                     │     50% inst A, 50% inst B         │
     │                                     │                                     │
     │                                     │  4. POST /payments                 │
     │                                     │  { customer: "cus_abc123",          │
     │                                     │    billingType: "PIX",             │
     │                                     │    value: 100.00,                  │
     │                                     │    splits: [                       │
     │                                     │      { walletId: "wallet_A",       │
     │                                     │        percentualValue: 50 },      │
     │                                     │      { walletId: "wallet_B",       │
     │                                     │        percentualValue: 50 }       │
     │                                     │    ]                               │
     │                                     │  ─────────────────────────────────→│
     │                                     │                                     │
     │                                     │  ← { id: "pay_123abc",             │
     │                                     │      invoiceUrl: "https://...",     │
     │                                     │      pixCopyPaste: "00020...",      │
     │                                     │      pixQrCode: "base64...",        │
     │                                     │      value: 100.00,                │
     │                                     │      status: "PENDING" }           │
     │                                     │  ←─────────────────────────────────│
     │                                     │                                     │
     │                                     │  5. Cria Donation                  │
     │                                     │     asaas_payment_id: pay_123abc   │
     │                                     │     status: pending                │
     │                                     │                                     │
     │                                     │  6. Cria DonationSplits            │
     │                                     │     inst A: 50%, pending           │
     │                                     │     inst B: 50%, pending           │
     │                                     │                                     │
     │  { donation_id,                    │                                     │
     │    pix_copy_paste,                 │                                     │
     │    pix_qr_code,                    │                                     │
     │    amount_brl,                     │                                     │
     │    expires_at }                    │                                     │
     │ ←──────────────────────────────────│                                     │
```

### 3.2 Doador Paga PIX

```
┌─────────┐                          ┌─────────┐
│  Doador │                          │  Asaas  │
└────┬────┘                          └────┬────┘
     │                                     │
     │  Copia pix_copy_paste              │
     │  ou escaneia QR Code               │
     │                                     │
     │  Paga R$ 100,00 via PIX            │
     │ ──────────────────────────────────→│ (banco)
     │                                     │
```

### 3.3 Webhook: Pagamento Recebido

```
┌─────────┐                          ┌─────────┐                          ┌─────────┐
│  Asaas  │                          │  Clareo │                          │  PG     │
└────┬────┘                          └────┬────┘                          └────┬────┘
     │                                     │                                     │
     │  POST /api/v1/webhooks/asaas       │                                     │
     │  {                                 │                                     │
     │    event: "PAYMENT_RECEIVED",      │                                     │
     │    payment: {                      │                                     │
     │      id: "pay_123abc",             │                                     │
     │      status: "RECEIVED",           │                                     │
     │      value: 100.00,                │                                     │
     │      splits: [                     │                                     │
     │        { status: "PENDING" },      │                                     │
     │        { status: "PENDING" }       │                                     │
     │      ]                             │                                     │
     │    }                               │                                     │
     │  }                                 │                                     │
     │ ──────────────────────────────────→│                                     │
     │                                     │                                     │
     │                                     │  1. Busca Donation por              │
     │                                     │     asaas_payment_id                │
     │                                     │                                     │
     │                                     │  2. Atualiza Donation               │
     │                                     │     status: received                │
     │                                     │                                     │
     │                                     │  3. Log evento                      │
     │                                     │                                     │
     │  200 OK                             │                                     │
     │ ←──────────────────────────────────│                                     │
```

### 3.4 Webhook: Split Concluído

```
┌─────────┐                          ┌─────────┐                          ┌─────────┐
│  Asaas  │                          │  Clareo │                          │  PG     │
└────┬────┘                          └────┬────┘                          └────┬────┘
     │                                     │                                     │
     │  POST /api/v1/webhooks/asaas       │                                     │
     │  {                                 │                                     │
     │    event: "PAYMENT_SPLIT_DONE",    │                                     │
     │    payment: {                      │                                     │
     │      id: "pay_123abc",             │                                     │
     │      splits: [                     │                                     │
     │        { status: "DONE" },         │                                     │
     │        { status: "DONE" }          │                                     │
     │      ]                             │                                     │
     │    }                               │                                     │
     │  }                                 │                                     │
     │ ──────────────────────────────────→│                                     │
     │                                     │                                     │
     │                                     │  1. Busca Donation                  │
     │                                     │                                     │
     │                                     │  2. Atualiza Donation               │
     │                                     │     status: split_done              │
     │                                     │                                     │
     │                                     │  3. Atualiza DonationSplits         │
     │                                     │     status: done (cada um)          │
     │                                     │                                     │
     │  200 OK                             │                                     │
     │ ←──────────────────────────────────│                                     │
```

---

## Fluxo 4: Instituição Recebe Split

```
┌──────────────┐                    ┌─────────┐                          ┌─────────┐
│  Instituição │                    │  Asaas  │                          │  Banco  │
└──────┬───────┘                    └────┬────┘                          └────┬────┘
       │                                 │                                     │
       │                                 │  Split creditado na subconta       │
       │                                 │  wallet_id: wallet_A               │
       │                                 │                                     │
       │  PIX instantâneo               │                                     │
       │  (saque da subconta)           │                                     │
       │ ←──────────────────────────────│                                     │
       │                                 │                                     │
```

**Instituição recebe automaticamente. Não precisa fazer nada.**

---

## Fluxo 5: Consulta de Doação

```
┌─────────┐                          ┌─────────┐
│  Doador │                          │  Clareo │
└────┬────┘                          └────┬────┘
     │                                     │
     │  GET /api/v1/donations/:id         │
     │ ──────────────────────────────────→│
     │                                     │
     │                                     │  Busca Donation + DonationSplits
     │                                     │
     │  { donation: {                     │
     │    id, amount_brl, status,         │
     │    splits: [                       │
     │      { institution, amount,        │
     │        percentual, status }        │
     │    ]                               │
     │  }}                                │
     │ ←──────────────────────────────────│
```

---

## Estados das Transações

### Donation

```
pending → received → split_done
    │         │          │
    └─────────┴──────────┴─→ failed
```

| Estado | Descrição |
|--------|-----------|
| `pending` | PIX aguardando pagamento |
| `received` | PIX recebido, aguardando split |
| `split_done` | Split concluído, instituições creditadas |
| `failed` | Pagamento falhou ou expirou |
| `refunded` | Pagamento estornado |

### DonationSplit

```
pending → awaiting_credit → done
    │           │              │
    └───────────┴──────────────┴─→ cancelled/refused
```

| Estado | Descrição |
|--------|-----------|
| `pending` | Split aguardando processamento |
| `awaiting_credit` | Aguardando crédito na subconta |
| `done` | Split creditado com sucesso |
| `cancelled` | Split cancelado |
| `refused` | Split recusado |
| `refunded` | Split estornado |

---

## Tratamento de Erros

### Webhook Idempotente

```ruby
# O Asaas pode reenviar webhooks se não receber 200
# Idempotência: verificar se já foi processado

def handle_payment_received(payment_id)
  donation = Donation.find_by(asaas_payment_id: payment_id)
  return if donation&.received? || donation&.split_done?  # Já processado

  DonationService.confirm(payment_id)
end
```

### Split Bloqueado

```ruby
# Se splits ultrapassam netValue, bloqueio por 2 dias úteis
# Webhook: PAYMENT_SPLIT_DIVERGENCE_BLOCK

def handle_split_blocked(payment_id)
  donation = Donation.find_by!(asaas_payment_id: payment_id)
  Rails.logger.warn "Split bloqueado para doação #{donation.id}"
  # Notificar admin
end
```

### Split Expirado

```ruby
# Webhook: PAYMENT_SPLIT_DIVERGENCE_BLOCK_FINISHED

def handle_split_block_finished(payment_id)
  donation = Donation.find_by!(asaas_payment_id: payment_id)
  # Tentar novamente ou notificar admin
end
```

---

## Segurança

### Verificação de Webhook

```ruby
# Asaas usa assinatura no header
# Verificar documentação específica para método exato

def self.verify_webhook(request)
  # TODO: implementar verificação real
  # Provavelmente HMAC-SHA256
  true
end
```

### Proteção Contra Replay

```ruby
# Usar idempotência via asaas_payment_id único
# Se pagamento já foi processado, ignorar webhook
```

### Validação de Dados

```ruby
# Sempre validar:
# - JWT do usuário
# - CNPJ da instituição
# - Valor da doação > 0
# - Instituições existem e estão ativas
```
