# Legado — planejamento anterior

## Onde estão os diagramas

Os 30 arquivos PlantUML do planejamento anterior estão em
**[`doc/_arquivados/asaas/diagramas/`](../asaas/diagramas/)**:

```
doc/_arquivados/asaas/diagramas/
├── 01-VISAO-GERAL.puml ... 10-MODELO-CONCEITUAL.puml
├── MODELO-DADOS.puml
├── 7-DIAGRAMA-CLASSE.puml
├── estados/      (6 arquivos)
├── sequencias/   (10 arquivos)
└── implantacao/  (2 arquivos)
```

Os documentos que os referenciam estão em
[`doc/_arquivados/asaas/`](../asaas/):
[03-MODELO-CONCEITUAL.md](../asaas/03-MODELO-CONCEITUAL.md),
[04-DIAGRAMAS-SEQUENCIA.md](../asaas/04-DIAGRAMAS-SEQUENCIA.md),
[05-DIAGRAMAS-ESTADO.md](../asaas/05-DIAGRAMAS-ESTADO.md),
[06-MODELO-DADOS.md](../asaas/06-MODELO-DADOS.md),
[07-DIAGRAMA-CLASSE.md](../asaas/07-DIAGRAMA-CLASSE.md) e
[09-IMPLANTACAO.md](../asaas/09-IMPLANTACAO.md).

## Por que estão arquivados

Descrevem um produto divergente do que foi implementado.

| No planejamento antigo | No projeto atual |
|------------------------|------------------|
| `Campaign` | existe em `campaigns` |
| `Post` (feed de transparência) | existe em `posts` |
| `DonationReport` | substituído por `accountability_reports` |
| Planos Gratuito e Pro (freemium) | `free`, `pro`, `enterprise` |
| Interfaces `Pagavel`, `Autenticavel`, `Notificavel` | `PaymentGateway`, `CustomerRegistry`, `WebhookVerifier` |

O planejamento antigo previa 9 tabelas, sem campanha nem feed. O schema atual
tem 17 tabelas de domínio, incluindo `campaigns`, `posts`, `accounts`,
`ledger_entries`, `cost_centers`, `documents` e `accountability_reports`.

## Como ler

Como **registro de decisão**, não como especificação. Serve para entender
alternativas que foram consideradas e por que o caminho atual é diferente.

Para o sistema como ele é, use o [índice atual](../../00-INDEX.md) e os
[diagramas atuais](../../diagramas/README.md).
