# ARQUIVADO — não reflete mais o produto

> **Este documento descreve uma arquitetura que foi descartada.**
>
> O Clareo passou por uma mudança de modelo de negócio: as doações deixaram de
> ser convertidas para USDT e renderizadas em protocolo DeFi, e passaram a ser
> recebidas em BRL e rateadas diretamente pelo Asaas, uma instituição de
> pagamento autorizada pelo Banco Central.
>
> Consequência principal: **o Clareo não custodia mais dinheiro nem cripto.**
> A custódia é do Asaas. Isso elimina o risco regulatório de operar como
> custodiante de ativo virtual e elimina a dependência de Binance, TRON,
> TronWeb, JustLend e NOWPayments.
>
> O histórico importa para entender por que o modelo mudou. Nenhum destes
> documentos deve ser implementado.

## Documentos arquivados

| Arquivo | Tecnologia | Motivo do descarte |
|---------|-----------|--------------------|
| `05-INTEGRACAO-BINANCE.md` | Binance Spot API | Conversão BRL↔USDT deixou de existir |
| `06-INTEGRACAO-TRON.md` | TRON / TronWeb | Sem USDT TRC-20, não há rede TRON |
| `07-INTEGRACAO-JUSTLEND.md` | JustLend DAO | Sem USDT a depositar, não há yield |
| `08-INTEGRACAO-NOWPAYMENTS.md` | NOWPayments | Substituído pelo Asaas como provedor único |

## O modelo anterior, em uma frase

Doação em BRL → NOWPayments converte para USDT → Binance compra mais USDT →
TronWeb envia para a TRON → JustLend rende ~1,35% ao ano → beneficiário saca
convertendo de volta.

## O modelo atual

Doação em BRL → cobrança criada no Asaas com `split` → no recebimento o Asaas
reparte direto entre a subconta da instituição e a conta da Clareo.

## Docs que valem a pena ler no lugar

- [16-INTEGRACAO-ASAAS.md](../16-INTEGRACAO-ASAAS.md) — o provedor atual
- [04-FLUXOS.md](../04-FLUXOS.md) — os fluxos vigentes
- [11-CUSTOS-RECEITAS.md](../11-CUSTOS-RECEITAS.md) — por que o modelo antigo
  também estava errado economicamente