# Casos de Uso

## O que mostra

Atores externos e o que cada um pode fazer no Clareo. É o diagrama que descreve
a superfície funcional, antes de qualquer detalhe de implementação.

## Atores previstos

| Ator | Alcance |
|-------|---------|
| Visitante | Vê o feed público, sem autenticação |
| Doador | Faz doações, acompanha histórico |
| Instituição | Recebe doações, gerencia saque, documentos |
| Admin | Opera o marketplace |
| Asaas | Sistema externo: cobra, liquida split, envia webhook |

## Quando redesenhar

- ao surgir um fluxo novo para um ator
- ao um ator ganhar ou perder permissão
- ao mudar o escopo de um caso de uso existente

## Arquivos

| Arquivo | Descrição | Atualizado em |
|---------|-----------|---------------|
| _(nenhum)_ | — | — |

## Quando preencher

Esta pasta se conecta à **Fase 3 — Casos de uso** do
[roadmap](../../15-ROADMAP.md). Faz sentido desenhá-la quando os casos de uso
estiverem escritos; antes disso o diagrama seria chute.

## Como renderizar

Ver [../README.md](../README.md#como-renderizar).