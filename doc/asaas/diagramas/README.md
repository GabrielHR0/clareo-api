# Diagramas de Casos de Uso — Clareo

## Visão Geral

Este diretório contém os diagramas de casos de Uso do sistema Clareo, escritos em PlantUML.

## Arquivos

| Arquivo | Descrição |
|---------|-----------|
| `01-VISAO-GERAL.puml` | Visão geral do sistema com todos os atores e casos de uso principais |
| `02-DOADOR.puml` | Casos de uso do Doador (cadastro, doação, histórico) |
| `03-INSTITUICAO.puml` | Casos de uso da Instituição (receber splits, extrato) |
| `04-ADMIN.puml` | Casos de uso do Admin (gerenciar instituições, relatórios) |
| `05-INTEGRACAO-ASAAS.puml` | Integração com Asaas API (subcontas, cobranças, webhooks) |

## Como Renderizar

### Opção 1: PlantUML Online
1. Acesse [www.plantuml.com/plantuml](https://www.plantuml.com/plantuml)
2. Copie o conteúdo do arquivo `.puml`
3. Cole no editor
4. O diagrama será gerado automaticamente

### Opção 2: VS Code
1. Instale a extensão "PlantUML" de jebbs
2. Abra o arquivo `.puml`
3. Pressione `Alt + D` para visualizar

### Opção 3: CLI
```bash
# Instalar PlantUML (requer Java)
java -jar plantuml.jar 01-VISAO-GERAL.puml
```

### Opção 4: Docker
```bash
docker run -it --rm -v $(pwd):/data plantuml/plantuml /data/*.puml
```

## Atores do Sistema

| Ator | Tipo | Descrição |
|------|------|-----------|
| **Doador** | Pessoa | Usuário que faz doações via PIX |
| **Instituição** | Pessoa | Organização que recebe doações |
| **Admin** | Pessoa | Administrador do sistema Clareo |
| **Asaas** | Sistema | PSP (Payment Service Provider) que processa pagamentos e splits |

## Relacionamentos

### Include (<<include>>)
- Uso caso B é obrigatório para Uso caso A
- Representado por seta tracejada com `<<include>>`

### Extend (<<extend>>)
- Uso caso B é opcional para Uso caso A
- Representado por seta tracejada com `<<extend>>`

### Associação
- Conexão direta entre ator e caso de uso
- Representado por seta sólida `-->`

## Fluxo Principal

```
Doador → Seleciona Instituição → Define Valor → Paga PIX
    ↓
Asaas recebe pagamento
    ↓
Split automático → Instituições recebem
    ↓
Clareo registra e notifica
```
