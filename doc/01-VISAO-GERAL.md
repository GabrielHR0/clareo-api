# Clareo — Visão Geral

## O Problema

Doadores que querem ajudar projetos, instituições ou influenciadores enfrentam:
- Falta de transparência sobre para onde o dinheiro vai
- Taxas altas em plataformas tradicionais (10-15%)
- Lentidão em transferências internacionais
- Impossibilidade de gerar renda com o dinheiro parado

## A Solução

O **Clareo** é uma plataforma SaaS que:
1. Aceita doações em BRL via métodos digitais (PIX, cartão, boleto)
2. Converte automaticamente para USDT (criptomoeda estável)
3. Deposita em protocolos de yield (JustLend) para gerar rendimento
4. Permite que beneficiários recebam saques a qualquer momento

## Modelo de Receita

| Fonte | Descrição |
|-------|-----------|
| Taxa de serviço | 2% cobrado por doação |
| Yield gerado | Rendimento do USDT depositado (fica com a plataforma) |
| Planos SaaS | Básico (2.5%), Pro (2%), Enterprise (1.5%) |

## Stack Tecnológica

| Camada | Tecnologia |
|--------|------------|
| Backend | Ruby 4.0.6 + Rails 8.1.3 (API mode) |
| Web Server | Kino (Ractor-based, Rust Tokio/Hyper) |
| Banco | PostgreSQL |
| Cache/Filas | Redis + Sidekiq |
| Blockchain | TRON (TRC-20) via TronWeb |
| Criptografia | Binance API (conversão BRL↔USDT) |
| Yield | JustLend DAO |
| On/Off-ramp | NOWPayments (PIX) |

## Público-Alvo

- Instituições de caridade
- Influenciadores digitais
- Projetos comunitários
-ONGs e startups de impacto social

## Termos Chave

- **Custodial:** A plataforma mantém as chaves privadas das carteiras
- **USDT TRC-20:** Tether (stablecoin) na rede TRON
- **Yield:** Rendimento gerado ao emprestar USDT em protocolos DeFi
- **JustLend:** Protocolo de lending na rede TRON
