# Clareo — Roadmap

> Fases verificáveis, com critério de aceite. Cada fase entrega algo executável;
> a seguinte só começa quando a anterior fecha.

---

## Fase 0 — Fundação ✅

Ambiente e decisões estruturais.

- [x] Rails 8.1.3 API + Ruby 4.0.6
- [x] PostgreSQL 16 + Redis 7 + Sidekiq
- [x] RSpec + RuboCop (omakase)
- [x] Troca de servidor: kino → **agoo** (Linux/macOS only)
- [x] RSpec sem Rails para o domínio (`spec/domain_helper.rb`)
- [x] Correção de `config/application.rb` — `Dotenv.load` antes do `Bundler.require`

**Aceite:** `bundle exec rspec` e `rails zeitwerk:check` passam; `bin/rails server -u agoo` sobe.

> ⚠️ O projeto **não roda no Windows**. Agoo é Linux/macOS only. Desenvolver
> em WSL (Ubuntu), Ruby 3.2.3 ou superior.

---

## Fase 1 — Domínio ✅

Núcleo de negócio puro. Zero dependência de Rails ou do provedor.

- [x] Value objects: `Money`, `Percentage`, `CpfCnpj`, `PixKey`, `ExternalReference`, `Address`
- [x] Snapshots: `ChargeSnapshot`, `SubaccountSnapshot`, `TransferSnapshot`, `SubscriptionSnapshot`
- [x] Entidades: `Institution`, `Donation`, `DonationSplit`, `Payout`, `WebhookEvent`, `Plan`, `Subscription`
- [x] Services: `SplitPolicy` (faixas configuráveis), `SettlementPlan`
- [x] Invariantes: soma de split exatamente 100%, `settlement_strategy` imutável, cotação por assinatura
- [x] Ports de saída: 6 interfaces + 6 repositórios
- [x] 147 specs, sem banco
- [x] Teste de arquitetura: domínio sem Rails e sem vocabulário de provedor

**Aceite:** 147 exemplos verdes; `spec/architecture` falha o build se alguém vazar dependência.

---

## Fase 2 — Persistência

ActiveRecord como adapter secundário. Nada entra no domínio.

- [ ] 9 migrations com constraints e índices parciais
- [ ] AR records em `adapters/secondary/persistence/records/`
- [ ] Repositories implementando `Repositories::*`
- [ ] Mapeamento entidade ↔ record sem lógica de negócio
- [ ] Seeds dos 3 planos
- [ ] `rails_helper` operacional com banco de teste

**Aceite:** specs de repository com banco real; nenhum model toca regra de negócio.

Ordem de criação: `users` → `plans` → `institutions` → `subscriptions` →
`donations` → `donation_splits` → `payouts` → `webhook_events` → `audit_logs`.

---

## Fase 3 — Casos de Uso

`app/application/`. Só fala com domain e ports.

- [ ] `RegisterInstitution` — quota da assinatura, valida domínio, cria subconta
- [ ] `CreateDonation` — `SettlementPlan`, dedupe de pagador, cria cobrança
- [ ] `ConfirmDonation` — a partir de `ChargeSnapshot` canônico
- [ ] `BlockDonationSplit` / `UnblockDonationSplit`
- [ ] `PayOutInstitution` — agrega pendências antes de transferir
- [ ] `SubscribeInstitution` — 1 assinatura ativa por instituição
- [ ] Queries: instituição, balanco pendente, status de webhook

**Aceite:** todos os specs com fakes in-memory, sem HTTP e sem banco.

---

## Fase 4 — API HTTP

Adapters primários.

- [ ] Rotas, controllers e serializers Alba
- [ ] Autorização: token válido **e** recurso pertence ao usuário
- [ ] `POST /webhooks/asaas` — validar token, persistir, responder 200, enfileirar
- [ ] Jobs Sidekiq com idempotência e reprocessamento
- [ ] Rack::Attack em auth e criação de doação
- [ ] Tratamento de erro mapeando exceções de domínio para HTTP

**Aceite:** `POST /donations` cria cobrança real contra o sandbox e o webhook
confirma; reenviar o mesmo evento não duplica efeito.

---

## Fase 5 — Adapter do Asaas

O único lugar que conhece JSON e HTTP.

- [ ] `Adapters::Secondary::Asaas::HttpClient` — timeout, retry, backoff
- [ ] `CustomerRegistry` com dedupe por `externalReference` e por CPF/CNPJ
- [ ] `AccountManager` — `accessToken.apiKey` aninhado, persistir imediatamente
- [ ] `PaymentGateway` — `split` só com perna roteável, `billingType` mapeado
- [ ] `TransferService` — Pix externo e transferência interna
- [ ] `WebhookVerifier` — `secure_compare` do token
- [ ] Tradução de `errors[].code` para exceções de domínio
- [ ] Fakes in-memory equivalentes, com os mesmos specs de contrato

**Aceite:** homologação completa no sandbox; specs de contrato passam para fake
e adapter real.

---

## Fase 6 — Assinatura

- [ ] Cobrança recorrente no provedor
- [ ] Mapeamento de `SUBSCRIPTION_*`
- [ ] Alerta de `SUBSCRIPTION_SPLIT_DIVERGENCE_BLOCK`
- [ ] Cobrança manual de plano

**Aceite:** assinatura Pro ativa libera a 5ª instituição; ao ultrapassar,
`409 quota_exceeded`.

---

## Fase 7 — Operação

- [ ] Painel de reconciliação: reference sem `asaas_payment_id`, splits
      pendentes > 48h, instituições em análise > 60 dias
- [ ] Alerta de expiração da informação comercial da subconta
- [ ] Métricas: eventos por status, falhas de webhook, taxa efetiva por método
- [ ] Alerta de webhook reprocessado mais de N vezes
- [ ] Backup automático e teste de restauração

**Aceite:** uma falha de webhook aparece no painel sem alguém reportar.

---

## Fase 8 — Go-Live

- [ ] Revisão contábil e fiscal do rateio
- [ ] Contrato e papel da instituição de pagamento definido
- [ ] Teste de carga no `SplitPolicy` com mix real de métodos
- [ ] Revisão de segurança externa
- [ ] Runbook de incidente de split bloqueado
- [ ] Plano de rollback

**Aceite:** checklist de [16-INTEGRACAO-ASAAS.md](16-INTEGRACAO-ASAAS.md) concluído
em produção.

---

## Pendências que Precisam de Resposta Externa

Bloqueiam fases específicas. Não são resolvidas escrevendo código.

| Pendência | Bloqueia | Quem resolve |
|-----------|----------|--------------|
| Período de avaliação: 10 subcontas, R$ 2.000 por subconta, 60 dias | Dimensionamento do MVP | Contato com o provedor |
| Subconta exige CNPJ | Onboarding de pessoa física | Já desenhado: caminho `:pix_payout` |
| Header de idempotência para retry de `POST /v3/payments` | Fase 5 | Documentação do provedor |
| Payload completo de `PAYMENT_RECEIVED` | Fase 4 | Documentação do provedor |
| Provedor assina o webhook além do token? | Fase 5 | Documentação do provedor |
| 30 ou 100 Pix grátis por mês? | Break-even do `:pix_payout` | `Menu do Usuário > Taxas` |
| Taxas contratadas | Toda a projeção | `Menu do Usuário > Taxas` |
| Enquadramento fiscal da intermediação | Fase 8 | Contador |

---

## Fora de Escopo

Decidido e removido. Registrado em
[_arquivados/README.md](_arquivados/README.md).

- Conversão BRL↔USDT
- Rede TRON e carteiras TRC-20
- Yield em protocolo DeFi
- Custódia de chave privada
- Múltiplos provedores de pagamento

A porta `PaymentGateway` permite trocar o provedor sem tocar no domínio, mas
**não há plano para isso.** A coluna `asaas_*` no banco assume Asaas.