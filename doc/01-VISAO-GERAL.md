# Clareo — Visão Geral

## O Problema

Doadores que querem ajudar projetos, instituições ou influenciadores enfrentam:
- Falta de transparência sobre para onde o dinheiro vai
- Taxas altas em plataformas tradicionais (10-15%)
- Lentidão em transferências internacionais
- Impossibilidade de gerar renda com o dinheiro parado

## A Solução

O **Clareo** é uma plataforma SaaS que:
1. Aceita doações em BRL via PIX
2. Converte automaticamente para USDT (criptomoeda estável)
3. Deposita em protocolos de yield (Aave V3) para gerar rendimento
4. Permite que beneficiários recebam saques a qualquer momento

## Modelo de Receita

| Fonte | Descrição |
|-------|-----------|
| Taxa de serviço | 2% cobrado por doação |
| Yield gerado | Rendimento do USDT depositado (fica com a plataforma) |
| Planos SaaS | Básico (2.5%), Pro (2%), Enterprise (1.5%) |

## Stack Tecnológica

| Camada | Tecnologia | Justificativa |
|--------|------------|---------------|
| Backend | Ruby 4.0.6 + Rails 8.1 (API mode) | Produtividade, ecossistema |
| Web Server | **Kino** (Rust Tokio/Hyper + Ractors) | 1.5-1.7x mais throughput que Puma |
| Banco | PostgreSQL | Confiável, JSONB para metadata |
| Cache/Filas | Redis + Sidekiq | Jobs assíncronos, cache |
| Blockchain | TRON (TRC-20) + Solana | TRON: liquidez / Solana: fees baixas |
| Exchange | Binance API (principal) + Mercado Bitcoin (fallback) | Melhor preço + compliance |
| Yield | Aave V3 (3-5% APY) | Battle-tested, multi-chain |
| On/Off-ramp | NOWPayments (PIX widget) | Widget pronto, non-custodial |

## Por que Kino?

- **Performance:** 1.5-1.7x mais throughput que Puma em I/O
- **HTTP/2 nativo:** +79% sobre HTTP/1.1, sem nginx
- **Memória:** ~4x menos que Puma cluster
- **Ractor-ready:** Parallelismo real quando Rails suportar Ractors
- **Rust front-end:** Tokio/Hyper para I/O de alta performance
- **Config DSL familiar:** Mesmo estilo do Puma, fácil migração
- **Produção pronta:** Graceful drain, crash supervision, timeouts

> **Nota:** Rails ainda não suporta Ractors oficialmente. Kino roda em `:threaded` mode
> para Rails, mas já usa Rust para I/O — mesmo sem Ractors, é mais rápido que Puma.

## Público-Alvo

- Instituições de caridade
- Influenciadores digitais
- Projetos comunitários
- ONGs e startups de impacto social

## Termos Chave

- **Custodial:** A plataforma mantém as chaves privadas das carteiras
- **USDT TRC-20:** Tether (stablecoin) na rede TRON
- **Yield:** Rendimento gerado ao emprestar USDT em protocolos DeFi
- **Aave:** Maior protocolo de lending descentralizado
- **SPSAV:** Sociedade Prestadora de Serviços de Ativos Virtuais (regulamentação Brasil)
