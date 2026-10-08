# Pacotes

## O que mostra

As camadas da arquitetura hexagonal e as regras de dependência entre elas. É o
diagrama que dá suporte a uma afirmação cara do projeto: **o domínio não conhece
Rails nem o provedor de pagamentos**.

```
adapters (entrada e saída)
     ↓
application (casos de uso)
     ↓
domain (entidades, value objects, regras)   ← não depende de nada
     ↑
ports (interfaces)
```

## Quando redesenhar

- ao mover código entre camadas
- ao criar uma pasta nova em `app/`
- ao introduzir uma dependência que atravessa camada

## Arquivos

| Arquivo | Descrição | Atualizado em |
|---------|-----------|---------------|
| _(nenhum)_ | — | — |

## Verificação

A regra de dependência não é só documentada: é testada. O teste
`spec/architecture/domain_independence_spec.rb` falha o build se `app/domain`
referenciar ActiveRecord, ActiveSupport, `Time.current`, `validates`,
`belongs_to` ou vocabulário do provedor (`asaas`, `walletId`, `netValue`).

Se este diagrama contradisser o teste, é o teste que está certo.

## Quando preencher

O diagrama pode ser feito agora, a partir de `app/domain`, `app/ports`,
`app/application` e `app/adapters` como estão. Mas essa pasta está ligada à
**Fase 3** — sem casos de uso e controllers, `adapters/primary` ainda está
vazio e o diagrama ficaria incompleto de um jeito enganoso.

## Como renderizar

Ver [../README.md](../README.md#como-renderizar).