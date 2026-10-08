# Dados

## O que mostra

O modelo de dados relacional: as 9 tabelas, chaves estrangeiras, cardinalidade
e os índices que não são decorativos.

## Quando redesenhar

- ao mudar uma migration
- ao adicionar coluna ou tabela
- ao adicionar ou remover um índice
- ao mudar uma constraint

## Arquivos

| Arquivo | Descrição | Atualizado em |
|---------|-----------|---------------|
| _(nenhum)_ | — | — |

## Tabelas

| Tabela | Papel |
|--------|-------|
| `users` | Quem autentica; 1 usuário tem N instituições |
| `institutions` | Entidade de negócio, com estratégia de liquidação |
| `plans` | Catálogo de planos, sem cota: a assinatura é por instituição |
| `subscriptions` | 1 ativa por usuário |
| `donations` | Doação, com `reference` como chave de idempotência |
| `donation_splits` | Uma linha por perna do rateio |
| `payouts` | Repasse por Pix |
| `webhook_events` | Idempotência do webhook |
| `audit_logs` | Trilha de auditoria, append-only |

## Índices que sustentam regra de negócio

| Índice | Regra |
|--------|-------|
| `idx_subscriptions_one_active_per_institution` | uma assinatura ativa por instituição |
| `idx_payouts_one_per_donation` | um payout por doação — impede pagar a instituição duas vezes |
| `index_donations_on_reference` | `reference` é a chave de idempotência da cobrança |
| `index_webhook_events_on_provider_event_id` | entrega de webhook é *at least once* |

## Quando preencher

O schema já está aplicado e versionado em `db/schema.rb`, então o diagrama é
derivável agora.

## Como renderizar

Ver [../README.md](../README.md#como-renderizar).