# Asaas — Referência Completa

> Fontes verificadas em 08/09/2026.
> Base URLs: https://docs.asaas.com | https://www.asaas.com

---

## 1. Sobre a Empresa

| Item | Detalhe |
|------|---------|
| **Nome completo** | ASAAS Gestão Financeira Instituição de Pagamento S.A. |
| **CNPJ** | 19.540.550/0001-21 |
| **Fundação** | 2013 (projeto desde 2010) |
| **Sede** | Joinville, Santa Catarina |
| **Fundadores** | Piero e Diego Contezini |
| **Código bancário** | 461 |
| **Funcionários** | ~1.000+ |
| **Contas criadas** | 3,7 milhões |
| **Volume movimentado** | R$ 165,8 bilhões |
| **Cobranças pagas** | 534,3 milhões |

---

## 2. Regulação e Licenças

| Licença | Órgão | Ano | Detalhe |
|---------|-------|-----|---------|
| **Instituição de Pagamento (IP)** | Banco Central | 2021 | 31ª IP autorizada no Brasil |
| **Sociedade de Crédito Direto (SCD)** | Banco Central | 2022 | Para oferecer crédito |
| **Sociedade de Crédito, Financiamento e Investimento (SCFI)** | Banco Central | 2025/2026 | Licença de financeira |

**Capital social:** De R$ 1 milhão para R$ 10 milhões (com SCFI).

**Certificações:**
- PCI-DSS (segurança de dados de cartões)
- Autorizada pelo Banco Central do Brasil

---

## 3. Investidores

| Investidor | Tipo |
|------------|------|
| SoftBank | Fundo |
| BOND | Fundo |
| 23S | Fundo |
| Parallax | Fundo |
| Cventures | Fundo |
| Spectra | Fundo |
| Escala Capital | Fundo |
| Quartzo Capital | Fundo |
| Inovabra (Itaú) | Corporate |
| Endeavor | Aceleradora |

**Total investido:** Mais de R$ 1 bilhão em equity.

**FIDC:** R$ 100 milhões captados para crédito.

---

## 4. Reputação (Reclame Aqui)

| Indicador | Valor |
|-----------|-------|
| **Nota média** | 8,5/10 |
| **Reputação** | RA1000 (máxima) |
| **Taxa de resposta** | 98,8% |
| **Taxa de solução** | 90,9% |
| **Voltariam a fazer negócio** | 74,9% |
| **Reclamações (período)** | 1.730 |
| **Tempo médio de resposta** | 7 dias |

**Fonte:** Reclame Aqui (mar/2026 – ago/2026)

### Principais reclamações
- Bloqueio indevido de contas
- Demora na liberação de saldos
- Taxas de antecipação consideradas altas
- Suporte demorado em casos complexos

### Pontos fortes
- Taxa de solução alta (90,9%)
- Responde quase todas as reclamações (98,8%)
- Nota RA1000 (máxima do Reclame Aqui)

---

## 5. Produtos Relevantes para o Clareo

### 5.1 Conta Digital PJ
- Abertura gratuita
- Sem mensalidade
- Número de conta (agência e conta)
- Acesso ao SPI (PIX)
- Cartão Mastercard (débito/crédito)

### 5.2 Recebimentos
| Meio de Pagamento | Taxa |
|-------------------|------|
| PIX | R$ 0,49 por transação (após 3 meses promocionais) |
| Boleto | R$ 1,99 por transação |
| Cartão de débito | R$ 0,35 + 1,89% |
| Cartão de crédito (à vista) | R$ 0,49 + 2,99% |
| Cartão de crédito (2-6x) | R$ 0,49 + 3,49% |
| Cartão de crédito (7-12x) | R$ 0,49 + 3,99% |
| Cartão de crédito (13-21x) | R$ 0,49 + 4,29% |

**Nota:** Taxas promocionais para novos clientes (3 meses): R$ 0,99 por PIX/boleto.

### 5.3 Split de Pagamentos
- **Funcionalidade nativa** na API
- Divisão automática no momento do recebimento
- Suporta valor fixo ou percentual
- Sem limite de receiving wallets
- Cálculo sobre valor líquido (após taxas)
- Webhooks para acompanhamento

### 5.4 Subcontas
- Criação via API
- Cada subconta tem walletId próprio
- Permite split para terceiros
- Ideal para marketplaces e plataformas

### 5.5 Outros Serviços
- Link de pagamento
- Checkout transparente
- Assinaturas (cobrança recorrente)
- Nota fiscal eletrônica (R$ 0,49/nota)
- Antecipação de recebíveis
- Notificações (WhatsApp, SMS, e-mail, voz)
- Negativação Serasa
- Consulta Serasa
- Pague contas
- ERP integrado

---

## 6. API — Visão Geral

### 6.1 URLs

| Ambiente | URL |
|----------|-----|
| Produção | https://api.asaas.com/v3 |
| Sandbox | https://sandbox.asaas.com/api/v3 |

### 6.2 Autenticação

```bash
curl -H 'access_token: YOUR_API_KEY' \
  https://api.asaas.com/v3/customers
```

### 6.3 Endpoints Principais

| Recurso | Método | Endpoint |
|---------|--------|----------|
| Criar cliente | POST | /v3/customers |
| Listar clientes | GET | /v3/customers |
| Criar cobrança | POST | /v3/payments |
| Listar cobranças | GET | /v3/payments |
| Criar assinatura | POST | /v3/subscriptions |
| Criar subconta | POST | /v3/subaccounts |
| Recuperar walletId | GET | /v3/wallets/{id} |
| Criar link pagamento | POST | /v3/paymentLinks |
| Transferir entre contas | POST | /v3/transfers |
| Webhooks | POST | /v3/webhooks |

### 6.5 Webhooks Disponíveis

| Evento | Descrição |
|--------|-----------|
| PAYMENT_RECEIVED | Pagamento recebido |
| PAYMENT_CONFIRMED | Pagamento confirmado |
| PAYMENT_OVERDUE | Pagamento vencido |
| PAYMENT_DELETED | Pagamento cancelado |
| PAYMENT_REFUNDED | Pagamento estornado |
| PAYMENT_SPLIT_DONE | Split concluído |
| PAYMENT_SPLIT_DIVERGENCE_BLOCK | Bloqueio por divergência no split |
| PAYMENT_SPLIT_DIVERGENCE_BLOCK_FINISHED | Bloqueio expirado |
| SUBSCRIPTION_CREATED | Assinatura criada |
| SUBSCRIPTION_DELETED | Assinatura cancelada |

---

## 7. Split de Pagamentos — Detalhes Técnicos

### 7.1 Como Funciona

```
1. Clareo cria subconta no Asaas para cada instituição
2. Clareo gera cobrança com splits configurados
3. Doador paga via PIX
4. Asaas desconta taxa (R$ 0,49)
5. Asaas divide automaticamente:
   - Instituição A recebe X%
   - Instituição B recebe Y%
6. Clareo recebe comissão (se aplicável)
7. Webhook notifica Clareo
```

### 7.2 Regras do Split

| Regra | Detalhe |
|-------|---------|
| Cálculo | Sobre valor líquido (após taxas) |
| Tipos | Percentual ou valor fixo |
| Combinação | Pode misturar fixo + percentual |
| Limite | Soma não pode ultrapassar 100% (percentual) ou netValue (fixo) |
| Conta remetente | Não pode estar no splits array |
| Contas destino | Devem ser subcontas Asaas |
| Bloqueio | Se ultrapassar netValue, bloqueia por 2 dias úteis |
| Estorno | Split é revertido automaticamente |

### 7.3 Status do Split

| Status | Significado |
|--------|-------------|
| PENDING | Split pendente |
| AWAITING_CREDIT | Aguardando crédito |
| DONE | Concluído |
| CANCELLED | Cancelado |
| REFUSED | Recusado |
| REFUNDED | Estornado |

### 7.4 Exemplo de Request

```json
{
  "splits": [
    {
      "walletId": "48548710-9baa-4ec1-a11f-9010193527c6",
      "fixedValue": 20.00
    },
    {
      "walletId": "0b763922-aa88-4cbe-a567-e3fe8511fa06",
      "percentualValue": 10.00
    }
  ]
}
```

---

## 8. Prazos de Liquidação

| Meio de Pagamento | Prazo |
|-------------------|-------|
| **PIX** | **Instantâneo** (alguns segundos) |
| Boleto (0h-13h29) | 17h do mesmo dia |
| Boleto (13h30-23h59) | 0h do dia seguinte |
| Boleto (após horário banco) | 2 dias úteis |
| Cartão de débito | 3 dias úteis |
| Cartão de crédito (à vista) | 32 dias corridos |
| Cartão de crédito (parcelado) | 32 dias por parcela |

---

## 9. Custos para o Clareo

### 9.1 Cenário: Doação de R$ 100 via PIX

| Etapa | Custo |
|-------|-------|
| Doador paga R$ 100 | — |
| Asaas desconta taxa PIX | R$ 0,49 |
| Split para instituições | Grátis (funcionalidade inclusa) |
| **Total gasto** | **R$ 0,49** |

### 9.2 Custos Mensais Estimados

| Item | Custo |
|------|-------|
| Conta PJ | Grátis |
| Mensalidade | Grátis |
| API | Grátis |
| Webhooks | Grátis |
| Split | Grátis |
| **Total fixo** | **R$ 0** |

---

## 10. Ruby SDK

### 10.1 Gem Oficial

```ruby
# Gemfile
gem 'asaas-ruby'
```

**Versão atual:** 0.2.30
**Última atualização:** Outubro 2024
**Downloads:** 74.755+
**Dependências:** rest-client, typhoeus, virtus, dry-types, dry-struct, dry-monads

### 10.2 Exemplo de Uso

```ruby
require 'asaas-ruby'

client = Asaas::Client.new('YOUR_API_KEY')

# Criar cliente
customer = client.customers.create(
  name: "Instituição ABC",
  cpfCnpj: "12345678901234",
  email: "contato@instituicao.com.br"
)

# Criar cobrança com split
payment = client.payments.create(
  customer: customer.id,
  billingType: "PIX",
  value: 100.00,
  splits: [
    {
      walletId: "48548710-9baa-4ec1-a11f-9010193527c6",
      percentualValue: 80.00
    }
  ]
)
```

### 10.3 Nota sobre o SDK

O SDK Ruby da Asaas (`asaas-ruby`) é mantido pela comunidade, não é oficial da empresa. Pode ser necessário usar HTTP direto para funcionalidades mais avançadas.

---

## 11. Limitações e Riscos

| Limitação | Impacto | Mitigação |
|-----------|---------|-----------|
| Split requer subcontas Asaas | Instituições devem criar conta | Clareo pode auxiliar no onboarding |
| Sem API banking (saldo, extrato) | Não consulta saldo via API | Usar webhooks para monitoramento |
| SDK Ruby não é oficial | Pode ter bugs | Testar bem, considerar HTTP direto |
| Bloqueio por divergência | Split bloqueado 2 dias | Monitorar webhooks |
| Antecipação sujeita a análise | Não garantida | Não usar como dependência |

---

## 12. Vantagens para o Clareo

| Vantagem | Detalhe |
|----------|---------|
| **Split nativo** | Funcionalidade pronta, sem customização |
| **PIX barato** | R$ 0,49 fixo por transação |
| **PIX instantâneo** | Institution recebe na hora |
| **Sem mensalidade** | Conta e API gratuitas |
| **Regulamentada** | Autorizada pelo Banco Central |
| **Boa reputação** | RA1000 no Reclame Aqui |
| **API completa** | Cobranças, webhooks, subcontas |
| **Investidores sólidos** | SoftBank, BOND, 23S |

---

## 13. Links Úteis

| Recurso | URL |
|---------|-----|
| Site | https://www.asaas.com |
| API Docs | https://docs.asaas.com |
| API Reference | https://docs.asaas.com/reference |
| Sandbox | https://sandbox.asaas.com |
| Split Docs | https://docs.asaas.com/docs/split-de-pagamentos |
| Preços | https://www.asaas.com/precos-e-taxas |
| Reclame Aqui | https://www.reclameaqui.com.br/empresa/asaas-gestao-financeira |
| Ruby Gem | https://rubygems.org/gems/asaas-ruby |
| GitHub SDK | https://github.com/eduardobernardo/asaas |
| Investors | https://investors.asaas.com |

---

## 14. Dados Corporativos

| Item | Detalhe |
|------|---------|
| **Razão social** | ASAAS Gestão Financeira Instituição de Pagamento S.A. |
| **CNPJ** | 19.540.550/0001-21 |
| **Endereço** | Av. Rolf Wiest, 277, Sl. 820 - Bom Retiro, Joinville - SC, 89223-005 |
| **Telefone** | 0800 009 0037 |
| **E-mail** | contato@asaas.com.br |
| **Segmento** | Fintech / Instituição de Pagamento |

---

*Documento gerado a partir de fontes públicas e verificáveis do Asaas em 08/09/2026.*
