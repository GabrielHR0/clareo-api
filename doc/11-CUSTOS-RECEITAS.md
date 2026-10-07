# Clareo — Custos e Receitas

> ⚠️ Este documento mudou materialmente. A versão anterior assumia taxa fixa de
> Pix de R$ 0,50 e taxa de serviço de 2%, o que dava margem de 45%. Isso era
> baseado em integração de stablecoin, sem taxa do provedor de pagamento. Com o
> Asaas, a taxa do Pix é **R$ 1,99 por transação recebida**, e a margem real é
> de **2% a 6%**. O modelo antigo não era viável no modelo antigo.

## O Problema da Taxa Flat

O provedor cobra **R$ 1,99 flat por transação recebida** no Pix e no boleto.
Isso não escala: em uma doação de R$ 20, a taxa consome 10% do valor inteiro.
Nenhum percentual único resolve isso — um percentual que cobre o valor de uma
doação pequena destrói a margem de uma grande.

Daí a `SplitPolicy` ser uma **tabela de faixas**, e não uma constante.

## SplitPolicy — Default Configurável

Definida em `app/domain/services/split_policy.rb`. Os valores estão em código
como dado, prontos para virar configuração persistida.

| Faixa de doação | Taxa retida pela Clareo |
|-----------------|-------------------------|
| até R$ 50,00 | 10% |
| R$ 50,01 a R$ 100,00 | 6% |
| R$ 100,01 a R$ 250,00 | 4% |
| acima de R$ 250,00 | 2,5% |

**Doação mínima: R$ 50,00.**

A faixa foi calibrada para que R$ 50,00 — o piso — ainda dê lucro positivo
depois da taxa do provedor. Abaixo disso a operação perde dinheiro por
doação.

## Conta por Doação (Pix)

O split incide sobre o **líquido**, nunca sobre o bruto.

```
líquido            = bruto − R$ 1,99
parcela Clareo     = taxa × líquido
parcela instituição = líquido − parcela Clareo
lucro              = parcela Clareo − R$ 1,99
```

| Doação | Taxa | Líquido | Clareo | Custo provedor | Lucro | Margem |
|--------|------|---------|--------|----------------|-------|--------|
| R$ 50,00 | 10% | R$ 48,01 | R$ 4,80 | R$ 1,99 | **R$ 2,81** | 5,62% |
| R$ 100,00 | 6% | R$ 98,01 | R$ 5,88 | R$ 1,99 | **R$ 3,89** | 3,89% |
| R$ 200,00 | 4% | R$ 198,01 | R$ 7,92 | R$ 1,99 | **R$ 5,93** | 2,97% |
| R$ 500,00 | 2,5% | R$ 498,01 | R$ 12,45 | R$ 1,99 | **R$ 10,46** | 2,09% |
| R$ 1.000,00 | 2,5% | R$ 998,01 | R$ 24,95 | R$ 1,99 | **R$ 22,96** | 2,30% |

### Caminho `:pix_payout` É Menos Lucrativo

Instituição sem CNPJ não tem subconta. O Clareo recebe 100% do líquido e paga
por Pix depois. Cada transferência custa — R$ 2,00 no plano padrão PJ, com
transferências gratuitas até um limite mensal.

| Doação | Lucro `:subaccount` | Lucro `:pix_payout` |
|--------|--------------------|---------------------|
| R$ 100,00 | R$ 3,89 | R$ 1,89 |
| R$ 500,00 | R$ 10,46 | R$ 8,46 |
| R$ 1.000,00 | R$ 22,96 | R$ 20,96 |

**Consequência operacional:** payouts no caminho `:pix_payout` só compensam quando
acumulados. Pagar R$ 2,00 para transferir R$ 3,89 destrói metade da margem. A
`Payout` deve agregar o que a instituição tem a receber antes de disparar a
transferência.

## Cartão Tem Outra Curva

A taxa de cartão é percentual mais um valor fixo menor, o que muda o
dimensionamento em doar R$ 100,00:

| Método | Taxa do provedor | Líquido | Clareo (6%) | Lucro | Margem |
|--------|------------------|---------|-------------|-------|--------|
| Pix | R$ 1,99 | R$ 98,01 | R$ 5,88 | R$ 3,89 | 3,89% |
| Cartão à vista | R$ 0,49 + 2,99% = R$ 3,48 | R$ 96,52 | R$ 5,79 | R$ 2,31 | 2,31% |
| Cartão 7-12x | R$ 0,49 + 3,99% = R$ 4,48 | R$ 95,52 | R$ 5,73 | R$ 1,25 | 1,25% |

**Parcelamento é bem mais magro que Pix.** A taxa incide sobre o valor total da
venda, então 12 parcelas com taxa de 3,99% custam quase o lucro inteiro.

O `SplitPolicy` é único para todos os métodos, calibrado pelo Pix por ser o mais
usado no Brasil. Se o mix migrar para cartão, a política precisa ser
diferenciada por método — o `Donation` já guarda `payment_method`, então a
mudança é local.

## Planos SaaS

O plano **não** define mais a taxa de split. A taxa vem da `SplitPolicy`, global
e por faixa. O plano limita quantidade de instituições.

| Plano | Preço | Instituições | Doações/mês |
|-------|-------|--------------|-------------|
| Básico | R$ 0 | 1 | até 100 |
| Pro | R$ 97/mês | 5 | até 1.000 |
| Enterprise | R$ 497/mês | ilimitado | ilimitado |

A assinatura é a receita **de margem praticamente 100%**: não tem custo variável
associado. É o que compensa a margem fina do split.

## Custo Fixo Mensal

| Item | Custo |
|------|-------|
| VPS (2 vCPU, 4GB) | R$ 50 – 100 |
| PostgreSQL gerenciado | R$ 50 – 100 |
| Redis gerenciado | R$ 20 – 50 |
| Domínio + SSL | R$ 10 |
| **Total** | **R$ 130 – 260** |

## Break-Even

Doação média de R$ 100,00:

| Custo fixo | Doações/mês (`:subaccount`) | Doações/mês (`:pix_payout`) |
|------------|---------------------------|-----------------------------|
| R$ 130 | 34 | 69 |
| R$ 260 | 67 | 138 |
| R$ 500 | 129 | 265 |
| R$ 1.000 | 257 | 530 |

Um break-even de 257 doações por mês é bastante acessível. O de 530, no caminho
`:pix_payout`, é apertado — e mais um argumento para agregar payouts.

## Projeção (`:subaccount`, R$ 100 de média)

| Mês | Doações | Parcela Clareo | Custo provedor | Lucro bruto | Custo fixo | Resultado |
|-----|---------|----------------|----------------|-------------|------------|-----------|
| 1 | 100 | R$ 588 | R$ 199 | R$ 389 | R$ 260 | R$ 129 |
| 3 | 250 | R$ 1.470 | R$ 498 | R$ 972 | R$ 260 | R$ 712 |
| 6 | 500 | R$ 2.940 | R$ 995 | R$ 1.945 | R$ 260 | R$ 1.685 |
| 12 | 1.000 | R$ 5.880 | R$ 1.990 | R$ 3.890 | R$ 260 | R$ 3.630 |

Sem assinaturas. Com 10 instituições Pro e 3 Enterprise, some R$ 2.461/mês de
receita de margem cheia — **o que muda o jogo mais que o volume de doações.**

## Como os Planos Cobrem a Margem Fina

Um Pro a R$ 97/mês que cobre 5 instituições representa R$ 19,40 por instituição.
Se cada instituição receber R$ 100 em doações por mês, isso compensa
integralmente a margem perdida no split.

É esse o argumento comercial: a assinatura é o que torna o modelo viável, não o
split. A tabela de planos precisa refletir esse argumento.

## ⚠️ Taxas Precisam ser Confirmadas

A página de preços do provedor diz **30 transferências Pix gratuitas por mês**
para pessoa jurídica. A central de ajuda diz **100 Pix gratuitos por mês**. Os
dois textos não concordam, e essa diferença muda o break-even do caminho
`:pix_payout`.

**Taxas são contratuais.** A tabela deste documento é a referência pública, não
a aplicada. Antes de usar qualquer número em decisão:

```
Menu do Usuário > Taxas
```

Referência: <https://www.asaas.com/precos-e-taxas>

## Margem de Yield: Removida

O modelo anterior tinha uma linha de receita de margem 100% — rendimento de USDT
em protocolo DeFi, ~1,35% ao ano. Ela **não existe mais**.

A ausência dessa linha é a principal mudança de perfil de risco e retorno:
troca-se receita de alto rendimento e alto risco regulatório por receita de
margem fina e risco baixo.

## Considerações Fiscais

- **Parcela da plataforma:** receita de serviço, tributada conforme regime
  escolhido.
- **Split não é receita da instituição:** é passagem de valor. A obrigação
  fiscal é do provedor como instituição de pagamento, mas a Clareo precisa
  conciliar e reportar.
- **Subcontas:** revisão anual de informação comercial é exigência regulatória do
  provedor — os eventos `ACCOUNT_STATUS_COMMERCIAL_INFO_EXPIRING_SOON` e
  `ACCOUNT_STATUS_COMMERCIAL_INFO_EXPIRED` precisam ser monitorados.
- **Contador:** necessário para o script de conciliação. Confirmar enquadramento
  de intermediação.