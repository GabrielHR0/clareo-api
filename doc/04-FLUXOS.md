# Clareo — Fluxos

> Cada fluxo indica o endpoint do Asaas envolvido e qual regra de domínio é
> acionada. Contratos em [16-INTEGRACAO-ASAAS.md](16-INTEGRACAO-ASAAS.md).

---

## Fluxo 1: Onboarding de Instituição com CNPJ

```
Usuário                  Clareo                      Asaas
  │                        │                            │
  │ 1. POST /institutions  │                            │
  │───────────────────────>│                            │
  │                        │ 2. valida domínio:         │
  │                        │    cnpj, income, endereço  │
  │                        │    settlement_strategy     │
  │                        │                            │
  │                        │ 3. quota: assinatura       │
  │                        │    permite outra instituição? │
  │                        │                            │
  │                        │ 4. POST /v3/accounts       │
  │                        │───────────────────────────>│
  │                        │                            │
  │                        │ 5. recebe walletId +       │
  │                        │    accessToken.apiKey      │
  │                        │<───────────────────────────│
  │                        │                            │
  │                        │ 6. PERSISTE apiKey AGORA   │
  │                        │    (retornada só 1x)       │
  │                        │                            │
  │ 7. 201 { status:       │                            │
  │      pending_approval} │                            │
  │<───────────────────────│                            │
  │                        │                            │
  │                    FRONTEND envia documentos         │
  │                        │                            │
  │              webhook: ACCOUNT_STATUS_DOCUMENT_*      │
  │                        │<───────────────────────────│
  │                        │                            │
  │                        │ 8. atualiza                │
  │                        │    registration_status     │
  │                        │                            │
  │              webhook: ACCOUNT_STATUS_GENERAL_        │
  │                      APPROVAL_APPROVED              │
  │                        │<───────────────────────────│
  │                        │                            │
  │                        │ 9. status = active         │
  │                        │                            │
  │ 10. GET /institutions  │                            │
  │    { accepts_donations: }                            │
  │      true }           │                            │
  │<───────────────────────│                            │
```

### Regras Acionadas

- `Institution` exige CNPJ, `legal_entity_kind`, `declared_monthly_revenue`,
  e-mail, telefone e endereço completo na estratégia `:subaccount`. Falha aqui,
  no domínio, e não com 400 do provedor.
- `Subscription#allows_another_institution?` barra o cadastro acima da cota do
  plano. Assinatura `past_due` ou `cancelled` não abre cota.
- `settlement_strategy` é definida no cadastro e **não tem setter**. Trocá-la com
  dinheiro em jogo não tem reversão segura.

### Ponto Crítico

`accessToken.apiKey` é retornada **uma única vez**. A mesma transação que cria a
subconta tem que persistir a chave. Se a chamada de criação for perdida, a
instituição fica recadastrável — mas o caminho antigo, órfão.

---

## Fluxo 2: Onboarding de Instituição sem CNPJ

Muito mais curto, porque não há subconta.

```
Usuário                  Clareo
  │                        │
  │ 1. POST /institutions  │
  │    { legal_name,       │
  │      pix_key }         │
  │───────────────────────>│
  │                        │ 2. settlement_strategy =    │
  │                        │    :pix_payout              │
  │                        │                            │
  │                        │ 3. exige pix_key            │
  │                        │ 4. status = active          │
  │                        │                            │
  │ 5. 201                 │
  │<───────────────────────│
```

Não há `walletId`, não há subconta, e portanto **não há split**. O Clareo recebe
100% do líquido e paga a instituição depois, por Pix.

É o único caminho disponível para pessoa física, já que o provedor só cria
subconta para CNPJ.

---

## Fluxo 3: Doação (caminho padrão)

Este é o fluxo principal. A cobrança é criada na conta **da Clareo**, com split
apontando para a subconta da instituição.

```
Doador                  Clareo                      Asaas
  │                        │                            │
  │ 1. POST /donations     │                            │
  │    { institution_id,   │                            │
  │      donor_name,       │                            │
  │      amount_brl,       │                            │
  │      payment_method }  │                            │
  │───────────────────────>│                            │
  │                        │                            │
  │                        │ 2. Institution#accepts_     │
  │                        │      donations?             │
  │                        │                            │
  │                        │ 3. SplitPolicy#             │
  │                        │    percentage_for(amount)   │
  │                        │                            │
  │                        │ 4. SettlementPlan → splits  │
  │                        │    (soma exatamente 100%)   │
  │                        │                            │
  │                        │ 5. dedupe pagador           │
  │                        │ 6. POST /v3/customers  ───>│ (se novo)
  │                        │<───────────────────────────│
  │                        │                            │
  │                        │ 7. POST /v3/payments        │
  │                        │    com split[ só instit. ]  │
  │                        │───────────────────────────>│
  │                        │<───────────────────────────│
  │                        │    status: PENDING          │
  │                        │    netValue: 98.01          │
  │                        │                            │
  │                        │ 8. Donation#pending         │
  │ 9. 201 { payment_url } │                            │
  │<───────────────────────│                            │
  │                        │                            │
  │              doador paga                               │
  │                        │                            │
  │   webhook PAYMENT_RECEIVED                            │
  │                        │<───────────────────────────│
  │                        │                            │
  │                        │ 10. PERSISTE evento         │
  │                        │     (idempotente por id)    │
  │                        │ 11. responde 200            │
  │                        │                            │
  │                        │ 12. GET /v3/payments/{id}    │
  │                        │───────────────────────────>│
  │                        │<───────────────────────────│
  │                        │     status: RECEIVED        │
  │                        │     netValue: 98.01         │
  │                        │                            │
  │                        │ 13. Donation#               │
  │                        │     confirm_receipt!        │
  │                        │                            │
  │                        │ 14. Asaas liquida o split    │
  │                        │     ┌────────────┐          │
  │                        │     │ instituição│ R$ 92,13 │
  │                        │     │ Clareo     │ R$  5,88 │
  │                        │     └────────────┘          │
  │                        │                            │
  │   webhook PAYMENT_SPLIT_DONE                         │
  │                        │<───────────────────────────│
  │                        │                            │
  │                        │ 15. DonationSplit#          │
  │                        │     mark_done!(total_value) │
  │                        │                            │
  │ 16. GET /donations/:id │                            │
  │    { status: received, │                            │
  │      net_amount: 98.01 }│                            │
  │<───────────────────────│                            │
```

### Regras Acionadas

- `Donation#amount` precisa ser positivo; o piso de negócio vem do
  `SplitPolicy.minimum_donation`.
- `SettlementPlan` gera sempre **duas** pernas: instituição e plataforma, somando
  exatamente 100%.
- `Donation#routable_splits` devolve **só** a perna da instituição. O adapter
  envia isso ao provedor — enviar o `walletId` da conta emitente causa exceção.

### O Ponto Mais Importante

**Passo 13 é o único caminho para `received`.** A resposta do passo 7 diz
`PENDING` e não prova nada — o pagamento pode nunca chegar. Confirmação vem
exclusivamente de webhook.

E o passo 12 existe porque o payload do webhook varia por evento e no exemplo vem
mínimo. O job **não** decide estado pelo que chegou: consulta a API. É a fonte da
verdade.

---

## Fluxo 4: Split Bloqueado por Divergência

```
Asaas                    Clareo
  │                        │
  │ detecta soma do split │
  │ > netValue             │
  │ bloqueia valor+split   │
  │                        │
  │ PAYMENT_SPLIT_         │
  │ DIVERGENCE_BLOCK       │
  │───────────────────────>│
  │                        │
  │ 1. Donation#           │
  │      block_split!      │
  │ 2. DonationSplit#block!│
  │ 3. alerta a instituição│
  │                        │
  │        2 dias úteis    │
  │                        │
  │                        │ 4. PUT /v3/payments/{id}    │
  │                        │    com split corrigido ────>│
  │                        │                            │
  │                        │ 5. Donation#unblock_split!  │
  │<───────────────────────│                            │
  │                        │                            │
  │   sem ajuste no prazo  │
  │                        │                            │
  │ PAYMENT_SPLIT_         │
  │ DIVERGENCE_BLOCK_      │
  │ FINISHED               │
  │───────────────────────>│
  │                        │ 6. Donation#cancel!         │
  │                        │ 7. split cancelado          │
  │                        │ 8. saldo liberado           │
```

Com apenas `percentualValue` a soma nunca passa de 100%, então divergência
exige mudança de proporção entre instituições ou de taxa da plataforma entre a
criação da cobrança e o recebimento.

Ao atualizar uma cobrança para corrigir o split, **omitir** `splits` não envia
`null` nem `[]` — isso desativa o split.

---

## Fluxo 5: Repasse por Pix (caminho `:pix_payout`)

Só instituições sem CNPJ. No caminho `:subaccount` a instituição saca direto
da própria subconta e o Clareo não intermediia.

```
Instituição               Clareo                      Asaas
  │                        │                            │
  │ 1. GET /institutions/  │                            │
  │    id/payoutable       │                            │
  │───────────────────────>│                            │
  │                        │ 2. soma entitlement de cada │
  │                        │    split sobre o líquido   │
  │                        │                            │
  │ 3. POST /payouts       │                            │
  │───────────────────────>│                            │
  │                        │ 4. Payout.new              │
  │                        │ 5. POST /v3/transfers      │
  │                        │    { pixKey, value } ─────>│
  │                        │<───────────────────────────│
  │                        │ 6. Payout#start_processing!│
  │ 7. 202 { status:       │                            │
  │      processing }      │                            │
  │<───────────────────────│                            │
  │                        │                            │
  │   webhook TRANSFER_DONE                            │
  │                        │<───────────────────────────│
  │                        │ 7. Payout#complete!        │
  │                        │                            │
  │   webhook TRANSFER_FAILED                           │
  │                        │<────────────────────────────│
  │                        │ 7. Payout#fail!            │
```

### Regra Crítica

Um payout por `(donation_id, institution_id)`, garantido por índice único
parcial. Retry de job que criasse dois payouts pagaria a instituição duas vezes
— o erro mais caro possível num produto que movimenta dinheiro de terceiros.

Payouts no caminho `:pix_payout` só se justificam se o valor acumulado for
relevante: cada transferência custa (ver [11-CUSTOS-RECEITAS.md](11-CUSTOS-RECEITAS.md)).

---

## Fluxo 6: Assinatura SaaS

```
Usuário                  Clareo                      Asaas
  │                        │                            │
  │ 1. POST /subscriptions │                            │
  │    { plan_code }       │                            │
  │───────────────────────>│                            │
  │                        │ 2. já existe assinatura   │
  │                        │    ativa?                  │
  │                        │                            │
  │                        │ 3. dedupe pagador ────────>│
  │                        │ 4. POST /v3/subscriptions  │
  │                        │───────────────────────────>│
  │                        │<───────────────────────────│
  │                        │ 5. Subscription             │
  │                        │    (1 ativa por usuário)    │
  │                        │                            │
  │                    cobrança recorrente               │
  │                        │      gerada pelo Asaas      │
  │                        │                            │
  │   webhook SUBSCRIPTION_UPDATED / INACTIVATED         │
  │                        │<───────────────────────────│
  │                        │ 6. atualiza status         │
  │                        │ 7. past_due → sem cota     │
  │                        │    para novas instituições │
```

### Regra Crítica

Uma assinatura ativa por usuário, garantido por índice parcial único em
`subscriptions (user_id) WHERE status = 'active'`. A regra não pode depender só
da aplicação.

`past_due` e `cancelled` retiram a cota de instituições, mas instituições
existentes continuam operando. Penalizar o doador de uma instituição por atraso
de assinatura não faz sentido.

---

## Fluxo 7: Autenticação

```
Cliente                  Clareo                      Redis
  │                        │                            │
  │ 1. POST /auth/login    │                            │
  │───────────────────────>│                            │
  │ 2. busca user, verifica│                            │
  │    senha (bcrypt)      │                            │
  │ 3. JWT HS256, exp 24h  │                            │
  │<───────────────────────│                            │
  │                        │                            │
  │ 4. GET /donations      │                            │
  │    Authorization:      │                            │
  │    Bearer <token>      │                            │
  │───────────────────────>│                            │
  │ 5. valida assinatura   │                            │
  │ 6. checa blacklist ────│───────────────────────────>│
  │ 7. authorization: a    │                            │
  │    instituição pertence│                            │
  │    ao usuário?         │                            │
  │<───────────────────────│                            │
```

Toda requisição autenticada valida **duas** coisas: que o token é válido e que o
usuário tem acesso ao recurso. Token válido não implica autorização — um
`institution_admin` não pode ler a doação de outra instituição só por ter um JWT
válido.

Ver [09-AUTHENTICATION.md](09-AUTHENTICATION.md).

---

## Fluxo 8: Job Assíncrono de Webhook

Todo webhook segue a mesma sequência, e a ordem é o que evita problemas
operacionais.

```
Asaas                    Controller              Sidekiq
  │                        │                        │
  │ POST /webhooks/asaas   │                        │
  │───────────────────────>│                        │
  │                        │ 1. valida              │
  │                        │    asaas-access-token   │
  │                        │    (secure_compare)    │
  │                        │                        │
  │                        │ 2. INSERT webhook_     │
  │                        │    events               │
  │                        │    ON CONFLICT DO       │
  │                        │    NOTHING             │
  │                        │    duplicata = 200      │
  │                        │                        │
  │ 3. HTTP 200            │                        │
  │<───────────────────────│                        │
  │                        │                        │
  │                        │ 4. enfileira job ──────>│
  │                        │                        │
  │                        │         5. marca        │
  │                        │            processing   │
  │                        │         6. GET /v3/     │
  │                        │            payments/{id}│
  │                        │         7. regra de     │
  │                        │            negócio      │
  │                        │         8. processed    │
  │                        │            ou failed    │
```

**Responder antes de processar.** Depois de **15 falhas consecutivas** a fila do
provedor é interrompida. Processar a regra de negócio antes de responder o
endpoint arrisca estourar esse limite.

**Rejeitar antes de persistir.** Token inválido não grava nada e devolve 401.

**Dedup no INSERT.** O provedor entrega *at least once*. O índice único em
`webhook_events.provider_event_id` com `ON CONFLICT DO NOTHING` faz o duplicado
ser fisicamente impossível.

**Reprocessar revalida estado.** Um evento antigo reprocessado pode encontrar a
entidade já atualizada por um evento mais novo. A regra precisa checar o estado
atual antes de agir de novo.