# 5. Diagramas de Estado de Objeto

## Visão Geral

Esta seção apresenta os diagramas de estado para as principais entidades do sistema Clareo. Cada diagrama descreve o lifecycle completo de um objeto, desde sua criação até seu estado final, incluindo todas as transições possíveis e os eventos que as disparam.

Os diagramas seguem a notação UML padrão, com estados representados por retângulos arredondados, transições por setas e eventos de trigger indicados nas setas. Estados iniciais são marcados com um círculo preenchido e estados finais com um círculo com alvo.

---

## 5.1 Donation (Doação)

A doação é a entidade com o lifecycle mais complexo do sistema, pois envolve a interação com o Asaas e múltiplos webhooks.

### Estados

| Estado | Descrição |
|--------|-----------|
| **pending** | Doação criada, PIX aguardando pagamento |
| **received** | PIX recebido, aguardando processamento do split |
| **split_done** | Split concluído, instituições creditadas (estado final normal) |
| **failed** | Pagamento falhou, expirou ou foi cancelado |
| **refunded** | Pagamento estornado pelo doador |

### Transições

| De | Para | Evento | Descrição |
|----|------|--------|-----------|
| [*] | pending | Criação da doação | Doação é registrada no sistema |
| pending | received | PAYMENT_RECEIVED | Asaas confirma recebimento do PIX |
| pending | failed | PAYMENT_OVERDUE | Pagamento expirou sem confirmação |
| pending | failed | PAYMENT_DELETED | Pagamento foi cancelado |
| received | split_done | PAYMENT_SPLIT_DONE | Split processado com sucesso |
| received | failed | PAYMENT_SPLIT_DIVERGENCE_BLOCK | Divergência no split (bloqueado) |
| pending | refunded | PAYMENT_REFUNDED | Doação estornada antes do recebimento |
| received | refunded | PAYMENT_REFUNDED | Doação estornada após recebimento |
| split_done | refunded | PAYMENT_REFUNDED | Doação estornada após split |

### Diagrama

**Arquivo:** `estados/01-DONATION.puml`

---

## 5.2 DonationSplit (Rateio)

O rateio representa a porção da doação destinada a uma instituição específica. Seu lifecycle é mais simples, pois depende apenas do processamento pelo Asaas.

### Estados

| Estado | Descrição |
|--------|-----------|
| **pending** | Split criado, aguardando processamento |
| **awaiting_credit** | Asaas processando a transferência |
| **done** | Split creditado na subconta (estado final normal) |
| **refused** | Asaas recusou o split |
| **cancelled** | Clareo cancelou o split |
| **refunded** | Split estornado |

### Transições

| De | Para | Evento | Descrição |
|----|------|--------|-----------|
| [*] | pending | Criação do split | Split é registrado junto com a doação |
| pending | awaiting_credit | Início do processamento | Asaas inicia o processamento |
| awaiting_credit | done | PAYMENT_SPLIT_DONE | Crédito confirmado na subconta |
| awaiting_credit | refused | Recusa do Asaas | Split recusado (divergência, saldo) |
| awaiting_credit | cancelled | Cancelamento pelo Clareo | Admin cancelou o split |
| done | refunded | PAYMENT_REFUNDED | Estorno do valor creditado |

### Diagrama

**Arquivo:** `estados/02-DONATION-SPLIT.puml`

---

## 5.3 Campaign (Campanha)

A campanha possui um lifecycle simples, controlado pela instituição e pelo tempo.

### Estados

| Estado | Descrição |
|--------|-----------|
| **active** | Campanha ativa, visível no feed, aceita doações |
| **paused** | Campanha pausada, oculta do feed, não aceita doações |
| **closed** | Campanha encerrada, não aceita doações |

### Transições

| De | Para | Evento | Descrição |
|----|------|--------|-----------|
| [*] | active | Criação da campanha | Campanha é criada ativa |
| active | paused | Pausa pela instituição | Instituição pausa a campanha |
| paused | active | Retomada pela instituição | Instituição retoma a campanha |
| active | closed | Data fim alcançada | Prazo da campanha expirou |
| active | closed | Encerramento pela instituição | Instituição encerra manualmente |
| paused | closed | Data fim alcançada | Prazo expirou mesmo pausada |
| paused | closed | Encerramento pela instituição | Instituição encerra manualmente |

### Diagrama

**Arquivo:** `estados/03-CAMPAIGN.puml`

---

## 5.4 Subscription (Assinatura)

A assinatura controla o acesso da instituição aos diferentes tiers de funcionalidade.

### Estados

| Estado | Descrição |
|--------|-----------|
| **active** | Assinatura ativa (gratuita ou Pro) |
| **pending** | Aguardando pagamento do upgrade |
| **canceled** | Assinatura cancelada pela instituição |
| **expired** | Assinatura expirada por falta de pagamento |

### Transições

| De | Para | Evento | Descrição |
|----|------|--------|-----------|
| [*] | active | Criação da conta | Assinatura gratuita criada automaticamente |
| active | pending | Solicitação de upgrade | Instituição solicita upgrade para Pro |
| pending | active | Pagamento confirmado | Asaas confirma o pagamento |
| pending | canceled | Cancelamento antes de pagar | Instituição desiste do upgrade |
| active | canceled | Cancelamento pela instituição | Instituição cancela a assinatura |
| canceled | expired | Período finalizado | Tempo da assinatura expirou |
| active | expired | Falta de pagamento | Pagamento não confirmado após vencimento |

### Diagrama

**Arquivo:** `estados/04-SUBSCRIPTION.puml`

---

## 5.5 Post (Publicação)

O post possui o lifecycle mais simples do sistema, pois é publicado imediatamente.

### Estados

| Estado | Descrição |
|--------|-----------|
| **published** | Post público, visível no feed |

### Transições

| De | Para | Evento | Descrição |
|----|------|--------|-----------|
| [*] | published | Criação do post | Post é criado com published_at = agora |

### Diagrama

**Arquivo:** `estados/05-POST.puml`

---

## 5.6 DonationReport (Relatório)

O relatório possui um lifecycle de geração, podendo falhar durante o processamento.

### Estados

| Estado | Descrição |
|--------|-----------|
| **generating** | Relatório sendo gerado |
| **generated** | Arquivo gerado com sucesso (estado final normal) |
| **failed** | Erro durante a geração |

### Transições

| De | Para | Evento | Descrição |
|----|------|--------|-----------|
| [*] | generating | Solicitação do relatório | Instituição solicita geração |
| generating | generated | Geração concluída | Arquivo PDF/CSV criado com sucesso |
| generating | failed | Erro na geração | Falha ao consultar banco ou gerar arquivo |

### Diagrama

**Arquivo:** `estados/06-DONATION-REPORT.puml`

---

## Resumo dos Diagramas

| # | Entidade | Estados | Transições | Complexidade |
|---|----------|---------|------------|--------------|
| 01 | Donation | 5 | 8 | Alta |
| 02 | DonationSplit | 6 | 6 | Média |
| 03 | Campaign | 3 | 5 | Baixa |
| 04 | Subscription | 4 | 6 | Média |
| 05 | Post | 1 | 1 | Mínima |
| 06 | DonationReport | 3 | 3 | Baixa |

Todos os diagramas estão disponíveis na pasta `doc/asaas/diagramas/estados/`.
