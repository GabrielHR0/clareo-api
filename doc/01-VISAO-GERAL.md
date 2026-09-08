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
3. Armazena em wallet segura (custódia)
4. Permite que instituições resgatem a qualquer momento via PIX

## Modelo de Receita

| Fonte | Descrição |
|-------|-----------|
| Taxa de serviço | 2% cobrado por doação |

## Stack Tecnológica

| Camada | Tecnologia |
|--------|------------|
| Backend | Ruby + Rails (API mode) |
| Banco | PostgreSQL |
| Cache/Filas | Redis + Sidekiq |
| Auth | JWT + bcrypt |

## Público-Alvo

- Instituições de caridade
- ONGs
- Projetos comunitários
- Startups de impacto social

## Termos Chave

- **Custodial:** A plataforma mantém as chaves privadas das carteiras
- **USDT:** Tether (criptomoeda estável 1:1 com USD)
- **PIX:** Sistema de pagamento instantâneo do Brasil
- **SPSAV:** Sociedade Prestadora de Serviços de Ativos Virtuais (regulamentação Brasil)
