# Classes

## O que mostra

Entidades, value objects e as interfaces de port. Agregados com seus
invariantes, e o que cada porta promete.

## Quando redesenhar

- ao adicionar entidade ou value object
- ao alterar um invariante de domínio
- ao mudar a assinatura de uma porta
- ao uma entidade ganhar ou perder transição de estado

## Arquivos

| Arquivo | Descrição | Atualizado em |
|---------|-----------|---------------|
| _(nenhum)_ | — | — |

## Agregados

Sete hoje, todos em `app/domain/entities/`:

| Agregado | Responsabilidade |
|----------|------------------|
| `Institution` | Instituição e sua estratégia de liquidação |
| `Donation` | Doação e seu estado |
| `DonationSplit` | Uma perna do rateio |
| `Payout` | Repasse por Pix |
| `WebhookEvent` | Idempotência de webhook |
| `Plan` | Plano e limite de instituições |
| `Subscription` | Assinatura do usuário |

## Invariantes que o diagrama precisa mostrar

- `Donation`: soma dos splits **exatamente** 100%; piso vem do `SplitPolicy`
- `Institution`: `settlement_strategy` imutável; exigências do provedor
- `Subscription`: uma ativa por usuário, garantida por índice parcial
- `DonationSplit`: split da plataforma não tem instituição

## Quando preencher

A **Fase 1 — Domínio** está concluída (24 arquivos em `app/domain`, 147
specs). O diagrama é derivável do código agora.

## Como renderizar

Ver [../README.md](../README.md#como-renderizar).