# Diagramas — Clareo

Diagramas em PlantUML (`.puml`), organizados por tipo. Um diagrama por
conceito, com o nome da pasta indicando o tipo.

Os diagramas entram aqui conforme o desenvolvimento avança, não antes. Um
diagrama que descreve algo que não existe é ficção; um que ficou velho sem ser
atualizado é pior.

## Pastas

| Pasta | O que mostra | Quando redesenhar |
|-------|--------------|-------------------|
| [`contexto/`](contexto/) | Visão geral do sistema e suas fronteiras | ao entrar ou sair uma integração externa |
| [`casos-de-uso/`](casos-de-uso/) | Atores e o que cada um pode fazer | ao surgir um fluxo novo para um ator |
| [`pacotes/`](pacotes/) | Camadas da arquitetura hexagonal e o que depende de quê | ao mover código entre camadas |
| [`classes/`](classes/) | Entidades, value objects, ports e os agregados | ao adicionar entidade ou mudar invariante |
| [`sequencia/`](sequencia/) | Troca de mensagens numa operação | ao criar um caso de uso |
| [`estados/`](estados/) | Ciclo de vida de um agregado | ao adicionar uma transição de estado |
| [`dados/`](dados/) | Modelo de dados relacional | ao mudar migration |
| [`implantacao/`](implantacao/) | Containers e topologia em produção | ao mudar deploy, infra ou porta |

Os diagramas do planejamento anterior estão em
[`doc/_arquivados/asaas/diagramas/`](../_arquivados/asaas/diagramas/), com o
contexto em [`doc/_arquivados/README.md`](../_arquivados/README.md).

## Estado atual

Nenhuma pasta tem diagramas ainda. Quando cada uma pode ser preenchida:

| Pasta | Depende de | Situação |
|-------|------------|----------|
| `classes/` | Domínio implementado | entidades e value objects em `app/domain`; pode ser feito agora |
| `dados/` | Persistência implementada | schema aplicado e migrations versionadas; pode ser feito agora |
| `estados/` | Domínio implementado | transições codificadas e testadas; pode ser feito agora |
| `implantacao/` | Operação | topologia local definida, produção não |
| `contexto/` | Integração Asaas | o provedor está decidido; o adapter ainda não existe |
| `pacotes/` | Casos de uso e API | `app/application` e `app/adapters/primary` já têm código |
| `casos-de-uso/` | Casos de uso e API | prestação de contas, rotas públicas e autenticação implementados |
| `sequencia/` | Casos de uso e API | há fluxos implementados para mapear |

"Depende de" indica o que ainda não existe e tornaria o diagrama fictionário.
Onde a coluna diz "pode ser feito agora", o diagrama descreveria código já
escrito e testado.

## Convenção de nome

```
NN-DESCRIACAO.puml
```

`NN` sequencial de dois dígitos, para o diretório em ordem alfabética manter a
ordem lógica. Descrição em maiúsculas com hífen no lugar de espaço.

Exemplos: `01-DONATION.puml`, `02-DONOR.puml`.

Atualizar o índice da tabela `## Arquivos` do README da pasta a cada diagrama
novo ou removido.

## Como renderizar

### Opção 1 — PlantUML online

1. Acesse <https://www.plantuml.com/plantuml>
2. Cole o conteúdo do `.puml`
3. O diagrama é gerado na hora

### Opção 2 — VS Code

Extensão **PlantUML** (jebbs), `Alt + D` para visualizar.

### Opção 3 — CLI

```bash
# requer Java
java -jar plantuml.jar doc/diagramas/classes/*.puml
```

### Opção 4 — Docker

```bash
docker run --rm -v "$PWD/doc/diagramas:/data" plantuml/plantuml /data/classes/*.puml
```

## Código-fonte

Os diagramas descrevem o código, não o substituem. Ao redesenhar, parta do
código atual, não do diagrama anterior:

| Diagrama | Fonte da verdade |
|----------|------------------|
| `pacotes/` | `app/domain`, `app/ports`, `app/application`, `app/adapters` |
| `classes/` | `app/domain` |
| `dados/` | `db/schema.rb` |
| `implantacao/` | `Dockerfile`, `Procfile.dev`, `bin/infra`, `config/` |