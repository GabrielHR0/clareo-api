# Sequência

## O que mostra

A troca de mensagens numa operação: quem chama quem, em que ordem, e onde cada
etapa pode falhar. É o diagrama que expõe problema de ordem — "o split já foi
configurado antes de a cobrança ser criada?".

## Quando redesenhar

- ao criar um caso de uso
- ao mudar a ordem de chamadas numa operação
- ao adicionar um passo assíncrono
- ao introduzir uma transação que não existia

## Arquivos

| Arquivo | Descrição | Atualizado em |
|---------|-----------|---------------|
| _(nenhum)_ | — | — |

## Candidatos naturais

O domínio já define o fluxo de cada operação, e os casos de uso estão em
[04-FLUXOS.md](../../04-FLUXOS.md):

| Operação | Ponto crítico que o diagrama expõe |
|----------|--------------------------------------|
| Doação | a resposta da criação da cobrança **não** confirma pagamento |
| Split | o split incide sobre o **líquido**, nunca sobre o bruto |
| Webhook | o webhook é gatilho; a API é a fonte da verdade |
| Payout | um por `(donation_id, institution_id)` |

## Quando preencher

**Fase 3 — Casos de uso** e **Fase 4 — API HTTP**.

## Como renderizar

Ver [../README.md](../README.md#como-renderizar).