# Estados

## O que mostra

O ciclo de vida de um agregado: quais estados existem, quais transições são
válidas e o que dispara cada uma.

## Quando redesenhar

- ao adicionar uma transição de estado
- ao um estado virar final
- ao uma transição ser bloqueada por regra de negócio

## Arquivos

| Arquivo | Descrição | Atualizado em |
|---------|-----------|---------------|
| _(nenhum)_ | — | — |

## Estados já definidos

Seis agregados têm máquina de estados. As transições estão codificadas e
testadas; abaixo está a leitura extraída de `app/domain/entities`, com o método
que faz cada transição e os status de origem que ele aceita.

Todos usam `transition_to!(allowed_from, target)`, que levanta
`Invalid*` quando a origem não está na lista. `WebhookEvent` escreve a guarda à
mão em vez de chamar o helper, mas a semântica é a mesma.

| Agregado | Guarda | Estados finais |
|----------|--------|----------------|
| `Donation` | `transition_to!` | `refunded`, `cancelled`, `rejected` |
| `Institution` | `transition_to!` | `blocked` (mas `submit_for_approval!` reabre) |
| `Payout` | `transition_to!` | `completed`, `failed`, `cancelled` |
| `DonationSplit` | `transition_to!` | `done`, `cancelled` |
| `WebhookEvent` | `unless ... include?` à mão | `processed` |
| `Subscription` | `transition_to!` | `cancelled`, `expired` |

### `Donation`

`STATUSES` = `pending`, `received`, `refunded`, `cancelled`, `rejected`,
`split_blocked`. Finais: `refunded`, `cancelled`, `rejected`.

```
                    ┌──────────────── refund! ──────────────> refunded
                    │                                 (só de received)
                    │
pending ──confirm_receipt!──> received ──block_split!──> split_blocked
   │                              │                          │
   │ reject!                      │ confirm_receipt!         │ unblock_split!
   ▼                              └──────────────────────────┤
rejected (final)                                               ▼
   │                                                  pending
   │ cancel!
   ▼
cancelled (final)                      block_split! ──> split_blocked
                                          cancel! ─────> cancelled (final)
```

Transições, com os estados de origem que cada uma aceita:

| Método | De | Para |
|--------|-----|------|
| `confirm_receipt!` | `pending`, `split_blocked` | `received` |
| `refund!` | `received` | `refunded` |
| `reject!` | `pending` | `rejected` |
| `cancel!` | `pending`, `split_blocked` | `cancelled` |
| `block_split!` | `pending`, `received` | `split_blocked` |
| `unblock_split!` | `split_blocked` | `pending` |

Três coisas que o diagrama precisa mostrar e que um desenho apressado esconde:

- **`received` e `split_blocked` formam ciclo.** Uma doação recebida pode ter o
  split bloqueado e voltar a `received`. `unblock_split!` só volta para
  `pending`, nunca restaura `received`.
- **`split_blocked` não é beco sem saída:** aceita `confirm_receipt!`,
  `cancel!` e `unblock_split!`.
- **`confirm_receipt!` exige `asaas_payment_id` e `net_amount`.** O
  `net_amount` só existe depois do recebimento — é o valor líquido, nunca o
  bruto. Criar a cobrança responde `PENDING` e não prova pagamento; só o
  webhook move o estado.

### `Institution`

Dois eixos independentes. O diagrama tem que mostrar os dois, senão passa a
ideia errada de que aprovação e bloqueio são o mesmo movimento.

**`status`** — `draft`, `pending_approval`, `active`, `blocked`

| Método | De | Para |
|--------|-----|------|
| `submit_for_approval!` | `draft`, `blocked` | `pending_approval` |
| `approve_registration!` | `pending_approval`, `blocked` | `active` |
| `reject_registration!` | `pending_approval` | `blocked` |
| `block!` | qualquer `STATUSES` | `blocked` |

`block!` é a única transição sem origem restrita: de qualquer estado.

**`registration_status`** — `unregistered`, `pending`, `approved`, `rejected`

Não é uma máquina de estados: é o registro do provedor. `approve_registration!`
e `reject_registration!` gravam aqui além de mexer no `status`.
`accepts_donations?` exige `status == active` **e** `registration_status ==
approved`.

### `Subscription`

`STATUSES` = `active`, `past_due`, `cancelled`, `expired`.

| Método | De | Para |
|--------|-----|------|
| `cancel!` | `active`, `past_due` | `cancelled`, grava `cancelled_at` |
| `mark_past_due!` | `active` | `past_due` |

Uma assinatura cancelada ou expirada não volta a ficar inadimplente: isso
devolveria direito a registrar instituição a uma assinatura que o provedor já
encerrou. Um webhook atrasado que reprocesse o evento levanta
`InvalidSubscription` em vez de reabrir a assinatura.

`cancel!` a partir de `past_due` é válido: a cobrança já estava em atraso quando
o cancelamento chegou.

`expired` está em `STATUSES` mas não há método que produza esse status — só
entra pela construção.

`cancel_provider_subscription!` não muda status: zera o
`provider_subscription_id`, para reconciliar o lado do provedor com o local.

### `DonationSplit`

`STATUSES` = `pending`, `done`, `cancelled`, `blocked`.

| Método | De | Para |
|--------|-----|------|
| `mark_done!` | `pending`, `blocked` | `done`, grava `total_value` e `asaas_split_id` |
| `cancel!` | `pending`, `blocked` | `cancelled`, grava `cancellation_reason` |
| `block!` | `pending`, `done` | `blocked`, motivo fixo `:value_divergence_block` |

Espelha `Donation`: um split bloqueado pode ser confirmado quando a divergência
de valor é resolvida, e um split liquidado pode ser bloqueado se a divergência
aparecer depois. `done` e `cancelled` são finais.

`cancel!` valida o motivo contra `CANCELLATION_REASONS`, o conjunto de nove
razões que o provedor devolve. Sem essa validação, um símbolo inventado pelo
chamador chegaria ao banco como texto livre.

`done` é o estado que interessa: o split só conta para saque depois de
`routable?`, e é sobre `total_value` — o valor líquido — que o repasse é
calculado.

### `Payout`

`STATUSES` = `pending`, `processing`, `completed`, `failed`, `cancelled`.

| Método | De | Para |
|--------|-----|------|
| `start_processing!` | `pending` | `processing` |
| `complete!` | `pending`, `processing` | `completed` |
| `fail!` | `pending`, `processing` | `failed` |
| `cancel!` | `pending`, `processing` | `cancelled` |

`complete!` aceita `pending` direto: um Pix que já chegou confirmado quando o job
foi criado não precisa passar por `processing`. O diagrama tem que mostrar essa
aresta curta, senão sugere uma etapa que o código não exige.

### `WebhookEvent`

`STATUSES` = `received`, `processing`, `processed`, `failed`.

| Método | De | Para |
|--------|-----|------|
| `start_processing!` | `received`, `failed` | `processing` |
| `processed!` | `processing` | `processed` |
| `failed!` | `processing` | `failed` |

Este é o ciclo de **retry**: `failed → processing` é o que permite reprocessar
um evento que falhou, e `processed` é final. Como a entrega do provedor é
*at least once*, é este agregado que torna o duplicado inofensivo — `record`
falha em vez de duplicar.

As três guardas são escritas à mão, com `unless ... include?(status)`, em vez de
chamarem o `transition_to!` que os outros cinco agregados usam. A semântica é a
mesma; só a forma diverge.

## Quando preencher

As transições acima estão codificadas e testadas em `app/domain/entities`, então
o diagrama é derivável agora.

## Como renderizar

Ver [../README.md](../README.md#como-renderizar).