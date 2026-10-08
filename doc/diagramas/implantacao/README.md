# Implantação

## O que mostra

Containers, topologia de rede e o que roda onde em cada ambiente. Onde o TLS
termina, qual porta o servidor escuta, e o que cada serviço depende.

## Quando redesenhar

- ao mudar o Dockerfile ou o Procfile
- ao trocar o servidor web
- ao mudar porta ou número de réplicas
- ao introduzir cache, proxy ou serviço novo

## Arquivo

| Arquivo | Descrição | Atualizado em |
|---------|-----------|---------------|
| _(nenhum)_ | — | — |

## Topologia atual

```
Internet ──TLS/HTTP2──> Thruster ──> Agoo ──> Rails 8.1 API
                                                ├──> PostgreSQL 16
                                                └──> Redis 7 (Sidekiq)

Linha externa: ──HTTPS──> Asaas API v3
```

O **Thruster** termina TLS e serve HTTP/2; o **Agoo** serve a aplicação Rack.
O Agoo não termina TLS, então o Thruster é obrigatório em produção.

## Dois ambientes com topologias diferentes

| Ambiente | Banco | Redis |
|----------|-------|-------|
| Produção | Postgres gerenciado | Redis gerenciado, TLS, Thruster na frente |
| Local (WSL) | cluster systemd na 5432 | compilado local, `bin/infra start` |

O servidor **agoo** é Linux e macOS only. O projeto não roda no Windows.

## Quando preencher

**Fase 7 — Operação**, junto com a revisão de deploy.

## Como renderizar

Ver [../README.md](../README.md#como-renderizar).