# Legado — planejamento anterior

## Onde estão os diagramas

Os 30 arquivos PlantUML do planejamento anterior estão em
**[`doc/asaas/diagramas/`](../../asaas/diagramas/)**:

```
doc/asaas/diagramas/
├── 01-VISAO-GERAL.puml ... 10-MODELO-CONCEITUAL.puml
├── MODELO-DADOS.puml
├── 7-DIAGRAMA-CLASSE.puml
├── estados/      (6 arquivos)
├── sequencias/   (10 arquivos)
└── implantacao/  (2 arquivos)
```

Eles **não foram movidos** para preservar os links em
[03-MODELO-CONCEITUAL.md](../../asaas/03-MODELO-CONCEITUAL.md),
[04-DIAGRAMAS-SEQUENCIA.md](../../asaas/04-DIAGRAMAS-SEQUENCIA.md),
[05-DIAGRAMAS-ESTADO.md](../../asaas/05-DIAGRAMAS-ESTADO.md),
[06-MODELO-DADOS.md](../../asaas/06-MODELO-DADOS.md),
[07-DIAGRAMA-CLASSE.md](../../asaas/07-DIAGRAMA-CLASSE.md) e
[09-IMPLANTACAO.md](../../asaas/09-IMPLANTACAO.md).

## Por que não foram migrados

Descrevem um produto divergente do que foi implementado.

| No legado | No projeto atual |
|------------|------------------|
| `Campaign` | não existe |
| `Post` (feed de transparência) | não existe |
| `DonationReport` | não existe |
| Planos Gratuito e Pro (freemium) | `free`, `pro`, `enterprise` |
| Interfaces `Pagavel`, `Autenticavel`, `Notificavel` | `PaymentGateway`, `CustomerRegistry`, `WebhookVerifier` |

O schema implementado tem 9 tabelas: `users`, `institutions`, `plans`,
`subscriptions`, `donations`, `donation_splits`, `payouts`, `webhook_events`,
`audit_logs`. Nenhuma de campanha ou feed.

## Como ler

Como **registro de decisão**, não como especificação. Serve para entender
alternativas que foram consideradas e por que o caminho atual é diferente.

Para o sistema como ele é, use as pastas irmãs: [classes/](../classes/),
[pacotes/](../pacotes/), [dados/](../dados/).

## Quando isto sai daqui

Quando ninguém mais precisar consultar o planejamento anterior e os documentos
em `doc/asaas/` forem arquivados em
[`doc/_arquivados/`](../../_arquivados/), junto com os outros provedores
desconsiderados.