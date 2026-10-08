# Clareo — Documentação

> Plataforma SaaS de captação de doações, com rateio automático via split e
> repasse por Pix.

## Comece Aqui

1. [Visão Geral](01-VISAO-GERAL.md) — o produto, o modelo, a posição regulatória
2. [Arquitetura](02-ARQUITETURA.md) — hexagonal, camadas, regras de dependência

## Modelo e Dados

3. [Modelos de Dados](03-MODELOS-DADOS.md) — as 9 tabelas e as constraints
4. [Fluxos](04-FLUXOS.md) — onboarding, doação, split, payout, assinatura, webhook

## Integração

5. [Integração Asaas](16-INTEGRACAO-ASAAS.md) — contrato com o provedor

> O provedor é o Asaas. Subcontas para instituições, split na cobrança, saque por
> Pix. Ver [\_arquivados/README.md](_arquivados/README.md) para o modelo anterior
> e o motivo da troca.

## Autenticação e Segurança

6. [Autenticação JWT](09-AUTHENTICATION.md) — papéis, autorização, blacklist
7. [Segurança](10-SEGURANCA.md) — o que mudou, o que auditar

## Negócio

8. [Custos e Receitas](11-CUSTOS-RECEITAS.md) — a matemática das taxas

## Infraestrutura

9. [Deploy](12-DEPLOY.md) — Docker, WSL, produção
10. [API Endpoints](13-API-ENDPOINTS.md) — o contrato HTTP

## Referências

11. [Links Oficiais](14-REFERENCIAS.md) — documentação externa
12. [Roadmap](15-ROADMAP.md) — fases, pendências, o que está fora de escopo

---

## As Quatro Decisões que Definem o Produto

**1. Provedor único: Asaas.** Sem fallback, sem abstração preventiva. A porta
`PaymentGateway` permite trocar, mas não há plano para isso e as colunas do
banco são `asaas_*`.

**2. Split direto na cobrança.** A instituição recebe sua parcela no
recebimento, direto na subconta. O Clareo não intermediia o dinheiro de
terceiros no caminho principal.

**3. Dois caminhos de liquidação.** O provedor só cria subconta para CNPJ, e
parte do público é pessoa física. Instituições sem CNPJ recebem por Pix, com o
split virando registro contábil. Mesma economia, mecanismo diferente.

**4. Arquitetura hexagonal completa.** O domínio é Ruby puro e não conhece
Rails nem o provedor. Verificado em teste, não só documentado.

---

## Estado Atual

| Fase | Status |
|------|--------|
| 0 — Fundação | concluída |
| 1 — Domínio | concluída |
| 2 — Persistência | pendente |
| 3 — Casos de uso | pendente |
| 4 — API HTTP | pendente |
| 5 — Adapter do Asaas | pendente |
| 6 — Assinatura | pendente |
| 7 — Operação | pendente |
| 8 — Go-live | pendente |

147 exemplos de teste, sem banco de dados e sem Rails no domínio.

Ver [15-ROADMAP.md](15-ROADMAP.md) para o critério de aceite de cada fase e para
as pendências que dependem de resposta externa.

---

## Restrição de Plataforma

**O projeto não roda no Windows.** O servidor [agoo](https://github.com/ohler55/agoo)
é Linux e macOS only. Desenvolvimento em **WSL (Ubuntu)**.
Ver [12-DEPLOY.md](12-DEPLOY.md).