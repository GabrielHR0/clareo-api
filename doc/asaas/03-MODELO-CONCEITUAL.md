# 3.2 Modelo Conceitual do Sistema

## 3.2.1 Conceitos Refinados

A partir da identificação dos conceitos candidatos realizada na seção anterior, procedeu-se ao refinamento das entidades, eliminando redundâncias e consolidando conceitos relacionados. O resultado é um conjunto de **10 classes** que compõem o modelo conceitual do Clareo.

### Classes de Negócio

**User (Usuário)** — Classe central do sistema, representa qualquer pessoa com acesso à plataforma. Um usuário pode ser doador, membro de uma instituição ou administrador. A autenticação é realizada por email e senha, com controle de acesso baseado em papéis (roles).

**Institution (Instituição)** — Organização que recebe doações. Uma instituição é sempre vinculada a um usuário do tipo "institution" no sistema. Possui dados jurídicos (CNPJ), chave PIX para recebimento e uma subconta no Asaas onde os splits são creditados.

**Donation (Doação)** — Registro completo de uma contribuição financeira. Armazena o valor, os dados do pagador, o identificador no Asaas e o status atual do pagamento. Uma doação pode ser dividida entre múltiplas instituições através de splits.

**DonationSplit (Rateio)** — Representa a porção da doação destinada a uma instituição específica. Cada doação gera um ou mais splits, calculados automaticamente com base em percentuais ou valores fixos. O processamento é feito pelo Asaas.

**Campaign (Campanha)** — Iniciativa de arrecadação de fundos criada por uma instituição. Possui título, descrição, valor meta, data de início e término, e controle de progresso. As campanhas são funcionalidade exclusiva do tier Pro.

**Post (Publicação)** — Conteúdo publicado por instituições no feed de transparência. Pode ser uma atualização sobre o uso dos recursos, um comprovante ou um relatório. Os posts são visíveis publicamente.

**PostAttachment (Anexo)** — Arquivo associado a um post, como comprovantes, notas fiscais ou documentos que comprovam a aplicação do dinheiro doado.

**Subscription (Assinatura)** — Contrato de acesso a funcionalidades premium. Controla se a instituição está no tier gratuito ou Pro, o status do pagamento e o período vigente.

**DonationReport (Relatório)** — Documento consolidado gerado a partir dos dados de doações de um período específico. Contém totais, médias e resumos estatísticos para análise financeira.

---

## 3.2.2 Associações

As associações entre as classes representam os relacionamentos para os quais é necessário preservar memória no sistema.

**User — Institution (1:N)**
Um usuário pode estar vinculado a uma ou mais instituições. Na prática, cada instituição é representada por um único usuário no sistema, mas a modelagem permite flexibilidade para cenários futuros.

**User — Donation (1:N)**
Um usuário pode realizar múltiplas doações ao longo do tempo. Cada doação é registrada uma única vez para cada contribuição.

**Institution — DonationSplit (1:N)**
Uma instituição recebe múltiplos splits provenientes de diferentes doações. Cada split representa uma parcela específica recebida.

**Donation — DonationSplit (1:N)**
Uma doação pode ser dividida entre duas ou mais instituições, gerando múltiplos registros de split.

**Institution — Campaign (1:N)**
Uma instituição pode criar e gerenciar múltiplas campanhas de arrecadação ao longo do tempo.

**Campaign — Donation (N:M)**
Uma campanha pode receber múltiplas doações. Uma doação pode ser direcionada a uma campanha específica.

**Institution — Post (1:N)**
Uma instituição publica múltiplos posts no feed de transparência.

**Post — PostAttachment (1:N)**
Um post pode conter múltiplos arquivos anexos (comprovantes, documentos).

**Institution — Subscription (1:1)**
Cada instituição possui exatamente uma assinatura, que pode ser do tipo gratuito ou Pro.

**Institution — DonationReport (1:N)**
Uma instituição pode gerar múltiplos relatórios ao longo do tempo, cada um cobrindo um período diferente.

---

## 3.2.3 Atributos por Classe

### User
| Atributo | Tipo | Descrição |
|----------|------|-----------|
| id | Integer | Identificador único |
| name | String | Nome completo |
| email | String | Email (único, usado para login) |
| password_digest | String | Hash da senha (bcrypt) |
| role | Enum | Papel: donor, institution, admin |
| created_at | DateTime | Data de criação |
| updated_at | DateTime | Data de atualização |

### Institution
| Atributo | Tipo | Descrição |
|----------|------|-----------|
| id | Integer | Identificador único |
| name | String | Nome da instituição |
| cnpj | String | CNPJ (único) |
| description | Text | Descrição da instituição |
| pix_key | String | Chave PIX para contato |
| asaas_customer_id | String | ID do cliente no Asaas |
| asaas_wallet_id | String | ID da subconta no Asaas |
| active | Boolean | Se está ativa no sistema |
| created_at | DateTime | Data de criação |
| updated_at | DateTime | Data de atualização |

### Donation
| Atributo | Tipo | Descrição |
|----------|------|-----------|
| id | Integer | Identificador único |
| donor_name | String | Nome do doador |
| donor_email | String | Email do doador |
| amount_brl | Decimal | Valor da doação em R$ |
| fee_amount | Decimal | Taxa cobrada pelo Asaas |
| net_amount | Decimal | Valor líquido após taxas |
| asaas_payment_id | String | ID do pagamento no Asaas |
| asaas_payment_url | String | URL para pagamento |
| status | Enum | Status: pending, received, split_done, failed, refunded |
| metadata | JSON | Dados adicionais |
| created_at | DateTime | Data de criação |
| updated_at | DateTime | Data de atualização |

### DonationSplit
| Atributo | Tipo | Descrição |
|----------|------|-----------|
| id | Integer | Identificador único |
| amount | Decimal | Valor destinado à instituição |
| percentual | Decimal | Percentual da doação |
| asaas_split_id | String | ID do split no Asaas |
| status | Enum | Status: pending, awaiting_credit, done, cancelled, refused, refunded |
| metadata | JSON | Dados adicionais |
| created_at | DateTime | Data de criação |
| updated_at | DateTime | Data de atualização |

### Campaign
| Atributo | Tipo | Descrição |
|----------|------|-----------|
| id | Integer | Identificador único |
| title | String | Título da campanha |
| description | Text | Descrição detalhada |
| goal_amount | Decimal | Valor meta a ser atingido |
| current_amount | Decimal | Valor arrecadado até o momento |
| start_date | Date | Data de início |
| end_date | Date | Data de término |
| cover_image_url | String | URL da imagem de capa |
| status | Enum | Status: active, paused, closed |
| created_at | DateTime | Data de criação |
| updated_at | DateTime | Data de atualização |

### Post
| Atributo | Tipo | Descrição |
|----------|------|-----------|
| id | Integer | Identificador único |
| title | String | Título do post |
| content | Text | Conteúdo do post |
| post_type | Enum | Tipo: update, receipt, report |
| published_at | DateTime | Data de publicação |
| created_at | DateTime | Data de criação |
| updated_at | DateTime | Data de atualização |

### PostAttachment
| Atributo | Tipo | Descrição |
|----------|------|-----------|
| id | Integer | Identificador único |
| file_url | String | URL do arquivo |
| file_type | String | Tipo do arquivo (pdf, image, etc) |
| description | String | Descrição do arquivo |
| created_at | DateTime | Data de criação |
| updated_at | DateTime | Data de atualização |

### Subscription
| Atributo | Tipo | Descrição |
|----------|------|-----------|
| id | Integer | Identificador único |
| plan | Enum | Plano: free, pro |
| status | Enum | Status: active, canceled, expired |
| amount | Decimal | Valor mensal da assinatura |
| asaas_subscription_id | String | ID da assinatura no Asaas |
| current_period_start | Date | Início do período atual |
| current_period_end | Date | Fim do período atual |
| created_at | DateTime | Data de criação |
| updated_at | DateTime | Data de atualização |

### DonationReport
| Atributo | Tipo | Descrição |
|----------|------|-----------|
| id | Integer | Identificador único |
| period_start | Date | Início do período |
| period_end | Date | Fim do período |
| format | Enum | Formato: pdf, csv |
| file_url | String | URL do arquivo gerado |
| generated_at | DateTime | Data de geração |
| total_donations | Decimal | Total de doações no período |
| total_amount | Decimal | Valor total recebido |
| average_donation | Decimal | Média por doação |
| summary | JSON | Resumo estatístico |
| created_at | DateTime | Data de criação |
| updated_at | DateTime | Data de atualização |

---

## 3.2.4 Diagrama de Classes

O diagrama de classes que representa o modelo conceitual completo do sistema está disponível no arquivo:

```
doc/asaas/diagramas/10-MODELO-CONCEITUAL.puml
```

O diagrama utiliza notação UML padrão com:
- **Retângulos** representando classes
- **Linhas** representando associações
- **Multiplicidades** indicando quantidades (1, 0..*, 1..*, etc.)
- **Atributos** listados dentro de cada classe com seu tipo
- **Estereótipos** para indicar tipos especiais (<<enum>>, etc.)
