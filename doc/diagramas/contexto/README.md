# Contexto

## O que mostra

Visão geral do sistema e suas fronteiras: o Clareo, os atores que o usam, e os
sistemas externos com os quais conversa.

É o diagrama de nível mais alto. Serve para responder "com quem o Clareo troca
informação?" sem abrir nenhum outro arquivo.

## Quando redesenhar

- ao entrar ou sair uma integração externa
- ao surgir um ator novo (doador, instituição, admin, provedor)
- ao mudar o papel do Asaas no fluxo (emissor, recebedor de split)

## Arquivos

| Arquivo | Descrição | Atualizado em |
|---------|-----------|---------------|
| _(nenhum)_ | — | — |

## Observação do projeto

O provedor de pagamentos é o **Asaas**, que é quem efetivamente custodia o
dinheiro. O Clareo é fornecedor de tecnologia e não tem contato com recurso de
terceiro no caminho principal (split direto na cobrança).

Se o provedor mudar depois, o diagrama está errado.

## Como renderizar

Ver [../README.md](../README.md#como-renderizar).