# 7. Diagrama de Classe do Sistema

## 7.1 Visão Geral

O diagrama de classe do Clareo representa a estrutura estática do sistema, incluindo as classes de modelo, interfaces, classes de serviço, seus atributos, métodos e relacionamentos. O diagrama segue os princípios de design orientado a objetos, aplicando os padrões MVC (Model-View-Controller) e Delegate (para serviços).

---

## 7.2 Interfaces

As interfaces definem contratos que as classes de serviço devem implementar, garantindo flexibilidade e troca de implementação.

### Autenticavel

Contrato para operações de autenticação e autorização.

```
+ authenticate(email, password) : User
+ generate_token(user_id) : String
+ verify_token(token) : User
```

### Pagavel

Contrato para operações de pagamento e cobrança.

```
+ create_payment(params) : Payment
+ get_payment(id) : Payment
+ list_payments(filters) : Array
```

### Notificavel

Contrato para recepção e verificação de notificações externas.

```
+ send_webhook(event, data) : Boolean
+ verify_signature(signature, body) : Boolean
```

### Relatoravel

Contrato para geração e download de relatórios.

```
+ generate_report(params) : Report
+ download_report(id) : File
+ list_reports(institution_id) : Array
```

---

## 7.3 Classes de Modelo

### 7.3.1 User

Classe central do sistema, representa qualquer pessoa com acesso à plataforma.

**Atributos:**
| Atributo | Tipo | Visibilidade | Descrição |
|----------|------|--------------|-----------|
| id | Integer | private | Identificador único |
| name | String | private | Nome completo |
| email | String | private | Email (único, usado para login) |
| password_digest | String | private | Hash da senha (bcrypt) |
| role | String | private | Papel: donor, institution, admin |
| created_at | DateTime | private | Data de criação |
| updated_at | DateTime | private | Data de atualização |

**Métodos:**
| Método | Retorno | Descrição |
|--------|---------|-----------|
| initialize(params) | User | Construtor com parâmetros |
| has_secure_password() | void | Configura autenticação bcrypt |
| institutions() | Array | Lista instituições do usuário |
| donations() | Array | Lista doações do usuário |
| donor?() | Boolean | Verifica se é doador |
| institution?() | Boolean | Verifica se é instituição |
| admin?() | Boolean | Verifica se é admin |
| as_json() | Hash | Serialização para JSON |

---

### 7.3.2 Institution

Organização que recebe doações. Possui subconta no Asaas.

**Atributos:**
| Atributo | Tipo | Visibilidade | Descrição |
|----------|------|--------------|-----------|
| id | Integer | private | Identificador único |
| user_id | Integer | private | FK para user |
| name | String | private | Nome da instituição |
| cnpj | String | private | CNPJ (único) |
| description | Text | private | Descrição |
| pix_key | String | private | Chave PIX |
| asaas_customer_id | String | private | ID no Asaas |
| asaas_wallet_id | String | private | ID da subconta |
| active | Boolean | private | Se está ativa |
| created_at | DateTime | private | Data de criação |
| updated_at | DateTime | private | Data de atualização |

**Métodos:**
| Método | Retorno | Descrição |
|--------|---------|-----------|
| initialize(params) | Institution | Construtor |
| user() | User | Usuário proprietário |
| donation_splits() | Array | Splits recebidos |
| campaigns() | Array | Campanhas criadas |
| posts() | Array | Posts publicados |
| subscription() | Subscription | Assinatura atual |
| reports() | Array | Relatórios gerados |
| active?() | Boolean | Se está ativa |
| pro?() | Boolean | Se tem plano Pro |
| as_json() | Hash | Serialização JSON |

---

### 7.3.3 Donation

Registro de uma contribuição financeira.

**Atributos:**
| Atributo | Tipo | Visibilidade | Descrição |
|----------|------|--------------|-----------|
| id | Integer | private | Identificador único |
| user_id | Integer | private | FK para user (null se anônimo) |
| donor_name | String | private | Nome do doador |
| donor_email | String | private | Email do doador |
| amount_brl | Decimal(15,2) | private | Valor em R$ |
| fee_amount | Decimal(15,2) | private | Taxa Asaas |
| net_amount | Decimal(15,2) | private | Valor líquido |
| asaas_payment_id | String | private | ID no Asaas |
| asaas_payment_url | String | private | URL de pagamento |
| status | String | private | Status atual |
| metadata | JSON | private | Dados adicionais |
| created_at | DateTime | private | Data de criação |
| updated_at | DateTime | private | Data de atualização |

**Métodos:**
| Método | Retorno | Descrição |
|--------|---------|-----------|
| initialize(params) | Donation | Construtor |
| user() | User | Doador |
| donation_splits() | Array | Splits gerados |
| pending?() | Boolean | Se está pendente |
| received?() | Boolean | Se foi recebido |
| split_done?() | Boolean | Se split foi concluído |
| failed?() | Boolean | Se falhou |
| refunded?() | Boolean | Se foi estornado |
| update_status(status) | void | Atualiza status |
| as_json() | Hash | Serialização JSON |

---

### 7.3.4 DonationSplit

Rateio da doação entre instituições.

**Atributos:**
| Atributo | Tipo | Visibilidade | Descrição |
|----------|------|--------------|-----------|
| id | Integer | private | Identificador único |
| donation_id | Integer | private | FK para donation |
| institution_id | Integer | private | FK para institution |
| amount | Decimal(15,2) | private | Valor destinado |
| percentual | Decimal(5,2) | private | Percentual |
| asaas_split_id | String | private | ID no Asaas |
| status | String | private | Status atual |
| metadata | JSON | private | Dados adicionais |
| created_at | DateTime | private | Data de criação |
| updated_at | DateTime | private | Data de atualização |

**Métodos:**
| Método | Retorno | Descrição |
|--------|---------|-----------|
| initialize(params) | DonationSplit | Construtor |
| donation() | Donation | Doação origem |
| institution() | Institution | Instituição destino |
| pending?() | Boolean | Se está pendente |
| awaiting_credit?() | Boolean | Se aguarda crédito |
| done?() | Boolean | Se foi concluído |
| refused?() | Boolean | Se foi recusado |
| cancelled?() | Boolean | Se foi cancelado |
| refunded?() | Boolean | Se foi estornado |
| update_status(status) | void | Atualiza status |
| as_json() | Hash | Serialização JSON |

---

### 7.3.5 Campaign

Campanha de arrecadação de fundos.

**Atributos:**
| Atributo | Tipo | Visibilidade | Descrição |
|----------|------|--------------|-----------|
| id | Integer | private | Identificador único |
| institution_id | Integer | private | FK para institution |
| title | String | private | Título |
| description | Text | private | Descrição |
| goal_amount | Decimal(15,2) | private | Valor meta |
| current_amount | Decimal(15,2) | private | Valor arrecadado |
| start_date | Date | private | Data início |
| end_date | Date | private | Data fim |
| cover_image_url | String | private | Imagem de capa |
| status | String | private | Status atual |
| created_at | DateTime | private | Data de criação |
| updated_at | DateTime | private | Data de atualização |

**Métodos:**
| Método | Retorno | Descrição |
|--------|---------|-----------|
| initialize(params) | Campaign | Construtor |
| institution() | Institution | Instituição criadora |
| donations() | Array | Doações recebidas |
| active?() | Boolean | Se está ativa |
| paused?() | Boolean | Se está pausada |
| closed?() | Boolean | Se está encerrada |
| expired?() | Boolean | Se prazo expirou |
| progress_percent() | Float | Progresso em % |
| pause() | void | Pausa campanha |
| resume() | void | Retoma campanha |
| close() | void | Encerra campanha |
| as_json() | Hash | Serialização JSON |

---

### 7.3.6 Post

Publicação de transparência.

**Atributos:**
| Atributo | Tipo | Visibilidade | Descrição |
|----------|------|--------------|-----------|
| id | Integer | private | Identificador único |
| institution_id | Integer | private | FK para institution |
| title | String | private | Título |
| content | Text | private | Conteúdo |
| post_type | String | private | Tipo: update, receipt, report |
| published_at | DateTime | private | Data de publicação |
| created_at | DateTime | private | Data de criação |
| updated_at | DateTime | private | Data de atualização |

**Métodos:**
| Método | Retorno | Descrição |
|--------|---------|-----------|
| initialize(params) | Post | Construtor |
| institution() | Institution | Instituição autora |
| post_attachments() | Array | Anexos |
| update?() | Boolean | Se é atualização |
| receipt?() | Boolean | Se é comprovante |
| report?() | Boolean | Se é relatório |
| published?() | Boolean | Se está publicado |
| as_json() | Hash | Serialização JSON |

---

### 7.3.7 PostAttachment

Arquivo anexado a um post.

**Atributos:**
| Atributo | Tipo | Visibilidade | Descrição |
|----------|------|--------------|-----------|
| id | Integer | private | Identificador único |
| post_id | Integer | private | FK para post |
| file_url | String | private | URL do arquivo |
| file_type | String | private | Tipo do arquivo |
| description | String | private | Descrição |
| created_at | DateTime | private | Data de criação |
| updated_at | DateTime | private | Data de atualização |

**Métodos:**
| Método | Retorno | Descrição |
|--------|---------|-----------|
| initialize(params) | PostAttachment | Construtor |
| post() | Post | Post pai |
| pdf?() | Boolean | Se é PDF |
| image?() | Boolean | Se é imagem |
| as_json() | Hash | Serialização JSON |

---

### 7.3.8 Subscription

Assinatura da instituição (free/pro).

**Atributos:**
| Atributo | Tipo | Visibilidade | Descrição |
|----------|------|--------------|-----------|
| id | Integer | private | Identificador único |
| institution_id | Integer | private | FK para institution |
| plan | String | private | Plano: free, pro |
| status | String | private | Status: active, canceled, expired |
| amount | Decimal(10,2) | private | Valor mensal |
| asaas_subscription_id | String | private | ID no Asaas |
| current_period_start | Date | private | Início do período |
| current_period_end | Date | private | Fim do período |
| created_at | DateTime | private | Data de criação |
| updated_at | DateTime | private | Data de atualização |

**Métodos:**
| Método | Retorno | Descrição |
|--------|---------|-----------|
| initialize(params) | Subscription | Construtor |
| institution() | Institution | Instituição |
| free?() | Boolean | Se é gratuito |
| pro?() | Boolean | Se é Pro |
| active?() | Boolean | Se está ativa |
| canceled?() | Boolean | Se foi cancelada |
| expired?() | Boolean | Se expirou |
| features() | Array | Lista de funcionalidades |
| can_create_campaigns?() | Boolean | Se pode criar campanhas |
| can_post_updates?() | Boolean | Se pode postar |
| can_generate_reports?() | Boolean | Se pode gerar relatórios |
| as_json() | Hash | Serialização JSON |

---

### 7.3.9 DonationReport

Relatório financeiro gerado.

**Atributos:**
| Atributo | Tipo | Visibilidade | Descrição |
|----------|------|--------------|-----------|
| id | Integer | private | Identificador único |
| institution_id | Integer | private | FK para institution |
| period_start | Date | private | Início do período |
| period_end | Date | private | Fim do período |
| format | String | private | Formato: pdf, csv |
| file_url | String | private | URL do arquivo |
| generated_at | DateTime | private | Data de geração |
| total_donations | Integer | private | Total de doações |
| total_amount | Decimal(15,2) | private | Valor total |
| average_donation | Decimal(15,2) | private | Média por doação |
| summary | JSON | private | Resumo estatístico |
| created_at | DateTime | private | Data de criação |
| updated_at | DateTime | private | Data de atualização |

**Métodos:**
| Método | Retorno | Descrição |
|--------|---------|-----------|
| initialize(params) | DonationReport | Construtor |
| institution() | Institution | Instituição |
| pdf?() | Boolean | Se é PDF |
| csv?() | Boolean | Se é CSV |
| generated?() | Boolean | Se foi gerado |
| download_url() | String | URL de download |
| as_json() | Hash | Serialização JSON |

---

## 7.4 Classes de Serviço

### 7.4.1 AsaasService

Serviço de integração com a API do Asaas.

**Atributos:**
| Atributo | Tipo | Visibilidade | Descrição |
|----------|------|--------------|-----------|
| api_key | String | private | Chave de API |
| base_url | String | private | URL base da API |

**Métodos:**
| Método | Retorno | Descrição |
|--------|---------|-----------|
| initialize() | AsaasService | Construtor (lê ENV) |
| create_customer(params) | Hash | Cria cliente |
| create_subaccount(params) | Hash | Cria subconta |
| get_wallet(wallet_id) | Hash | Busca carteira |
| create_payment(params) | Hash | Cria cobrança |
| get_payment(id) | Hash | Busca pagamento |
| list_payments(params) | Hash | Lista pagamentos |
| create_subscription(params) | Hash | Cria assinatura |
| self.verify_webhook(request) | Boolean | Verifica assinatura |

---

### 7.4.2 DonationService

Serviço de negócio para doações.

**Métodos:**
| Método | Retorno | Descrição |
|--------|---------|-----------|
| create(params) | Donation | Cria doação com splits |
| confirm(asaas_payment_id) | Donation | Confirma pagamento |
| calculate_splits(ids, amount) | Array | Calcula splits |

---

### 7.4.3 CampaignService

Serviço de negócio para campanhas.

**Métodos:**
| Método | Retorno | Descrição |
|--------|---------|-----------|
| create(params, inst_id) | Campaign | Cria campanha |
| update(id, params) | Campaign | Atualiza campanha |
| pause(id) | Campaign | Pausa campanha |
| resume(id) | Campaign | Retoma campanha |
| close(id) | Campaign | Encerra campanha |

---

### 7.4.4 PostService

Serviço de negócio para posts.

**Métodos:**
| Método | Retorno | Descrição |
|--------|---------|-----------|
| create(params, inst_id) | Post | Cria post |
| update(id, params) | Post | Atualiza post |
| delete(id) | Boolean | Exclui post |
| add_attachment(post_id, file) | PostAttachment | Anexa arquivo |

---

### 7.4.5 ReportService

Serviço de negócio para relatórios.

**Métodos:**
| Método | Retorno | Descrição |
|--------|---------|-----------|
| generate(params, inst_id) | DonationReport | Gera relatório |
| calculate_stats(inst_id, period) | Hash | Calcula estatísticas |
| generate_file(report) | String | Gera arquivo PDF/CSV |

---

### 7.4.6 SubscriptionService

Serviço de negócio para assinaturas.

**Métodos:**
| Método | Retorno | Descrição |
|--------|---------|-----------|
| upgrade(inst_id) | Subscription | Faz upgrade para Pro |
| cancel(inst_id) | Subscription | Cancela assinatura |
| confirm(sub_id) | Subscription | Confirma pagamento |

---

### 7.4.7 WebhookService

Serviço de processamento de webhooks.

**Métodos:**
| Método | Retorno | Descrição |
|--------|---------|-----------|
| process(params) | Boolean | Processa webhook |
| handle_payment_received(id) | Donation | Processa pagamento |
| handle_split_done(id) | Donation | Processa split |
| handle_subscription_created(id) | Subscription | Processa assinatura |

---

## 7.5 Diagrama Completo

O diagrama de classe completo está disponível no arquivo:

```
doc/asaas/diagramas/7-DIAGRAMA-CLASSE.puml
```

### Resumo de Dependências

```
AsaasService implementa IPayable, INotifiable
DonationService depende de AsaasService
CampaignService depende de AsaasService
ReportService depende de Donation
SubscriptionService depende de AsaasService
WebhookService depende de AsaasService, DonationService, SubscriptionService
```

### Padrões Aplicados

- **MVC:** Modelos (User, Institution, etc), Services (business logic), Controllers (not shown)
- **Delegate:** Services delegam operações externas para AsaasService
- **Interface:** Autenticavel, Pagavel, Notificavel, Relatoravel
- **Active Record:** Modelos possuem métodos de persistência (save, update, destroy)
