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
| [`legado-asaas/`](legado-asaas/) | Ponteiro para o planejamento anterior | não se aplica |

## Estado atual

Nenhuma pasta tem diagramas ainda. Quando cada uma pode ser preenchida:

| Pasta | Depende de | Situação |
|-------|------------|----------|
| `classes/` | Fase 1 — Domínio | 24 arquivos em `app/domain`; pode ser feito agora |
| `dados/` | Fase 2 — Persistência | schema aplicado; pode ser feito agora |
| `estados/` | Fase 1 — Domínio | transições codificadas e testadas; pode ser feito agora |
| `implantacao/` | Fase 7 — Operação | topologia local definida, produção não |
| `contexto/` | Fase 5 — Adapter do Asaas | o provedor já está decidido |
| `pacotes/` | Fase 3 — Casos de uso | `app/application` e `app/adapters/primary` estão vazios |
| `casos-de-uso/` | Fase 3 — Casos de uso | depende dos casos de uso escritos |
| `sequencia/` | Fase 3 e Fase 4 | depende dos casos de uso |

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