# 6. Modelo de Dados do Sistema

## 6.1 Visão Geral

O modelo de dados do Clareo é composto por **9 tabelas** principais, projetadas para suportar todas as funcionalidades da plataforma: doações, splits, campanhas, transparência, relatórios e assinaturas. O banco de dados utilizado é o PostgreSQL, que oferece suporte nativo a tipos JSONB, indexação avançada e integridade referencial.

A estrutura do banco segue o padrão de naming conventions do Rails (snake_case), com chaves primárias auto-incrementais do tipo SERIAL, chaves estrangeiras com constraints de integridade e timestamps automáticos de criação e atualização.

---

## 6.2 Descrição das Tabelas

### 6.2.1 Tabela users

Armazena os dados de todos os usuários do sistema, independentemente de seu papel (doador, instituição ou admin). É a tabela central de autenticação e identificação.

| Coluna | Tipo | Constraints | Descrição |
|--------|------|-------------|-----------|
| id | SERIAL | PRIMARY KEY | Identificador único do usuário |
| name | VARCHAR(255) | NOT NULL | Nome completo |
| email | VARCHAR(255) | UNIQUE, NOT NULL | Email utilizado para login |
| password_digest | VARCHAR(255) | NOT NULL | Hash da senha (bcrypt) |
| role | VARCHAR(20) | NOT NULL | Papel: donor, institution, admin |
| created_at | TIMESTAMP | | Data e hora de criação |
| updated_at | TIMESTAMP | | Data e hora da última atualização |

**Índices:**
- `index_users_on_email` (único)
- `index_users_on_role`

---

### 6.2.2 Tabela institutions

Armazena os dados das organizações que recebem doações. Cada instituição é vinculada a um usuário do tipo "institution" e possui uma subconta no Asaas para receber splits.

| Coluna | Tipo | Constraints | Descrição |
|--------|------|-------------|-----------|
| id | SERIAL | PRIMARY KEY | Identificador único da instituição |
| user_id | INTEGER | FOREIGN KEY, NOT NULL | Referência ao usuário proprietário |
| name | VARCHAR(255) | NOT NULL | Nome da instituição |
| cnpj | VARCHAR(18) | UNIQUE, NOT NULL | CNPJ da organização |
| description | TEXT | | Descrição da instituição |
| pix_key | VARCHAR(255) | NOT NULL | Chave PIX para contato |
| asaas_customer_id | VARCHAR(50) | UNIQUE, NOT NULL | ID do cliente no Asaas |
| asaas_wallet_id | VARCHAR(50) | UNIQUE, NOT NULL | ID da subconta no Asaas |
| active | BOOLEAN | DEFAULT true | Se está ativa no sistema |
| created_at | TIMESTAMP | | Data e hora de criação |
| updated_at | TIMESTAMP | | Data e hora da última atualização |

**Índices:**
- `index_institutions_on_cnpj` (único)
- `index_institutions_on_asaas_customer_id` (único)
- `index_institutions_on_asaas_wallet_id` (único)
- `index_institutions_on_user_id`

**Relacionamento:** Uma instituição pertence a um usuário (`belongs_to :user`).

---

### 6.2.3 Tabela donations

Registra todas as doações recebidas pela plataforma. Cada doação contém os dados do pagador, o valor, o identificador no Asaas e o status atual do pagamento.

| Coluna | Tipo | Constraints | Descrição |
|--------|------|-------------|-----------|
| id | SERIAL | PRIMARY KEY | Identificador único da doação |
| user_id | INTEGER | FOREIGN KEY, NULL | Referência ao doador (null se anônimo) |
| donor_name | VARCHAR(255) | NOT NULL | Nome do doador |
| donor_email | VARCHAR(255) | NOT NULL | Email do doador |
| amount_brl | DECIMAL(15,2) | NOT NULL | Valor da doação em R$ |
| fee_amount | DECIMAL(15,2) | DEFAULT 0 | Taxa cobrada pelo Asaas |
| net_amount | DECIMAL(15,2) | DEFAULT 0 | Valor líquido após taxas |
| asaas_payment_id | VARCHAR(50) | UNIQUE, NOT NULL | ID do pagamento no Asaas |
| asaas_payment_url | VARCHAR(500) | | URL para pagamento |
| status | VARCHAR(20) | NOT NULL | Status: pending, received, split_done, failed, refunded |
| metadata | JSONB | DEFAULT '{}' | Dados adicionais em formato JSON |
| created_at | TIMESTAMP | | Data e hora de criação |
| updated_at | TIMESTAMP | | Data e hora da última atualização |

**Índices:**
- `index_donations_on_asaas_payment_id` (único)
- `index_donations_on_status`
- `index_donations_on_donor_email`

**Relacionamento:** Uma doação pode ter múltiplos splits (`has_many :donation_splits`).

---

### 6.2.4 Tabela donation_splits

Registra a divisão de cada doação entre as instituições destinatárias. Cada split representa a porção do valor total que será creditada em uma instituição específica.

| Coluna | Tipo | Constraints | Descrição |
|--------|------|-------------|-----------|
| id | SERIAL | PRIMARY KEY | Identificador único do split |
| donation_id | INTEGER | FOREIGN KEY, NOT NULL | Referência à doação |
| institution_id | INTEGER | FOREIGN KEY, NOT NULL | Referência à instituição |
| amount | DECIMAL(15,2) | NOT NULL | Valor destinado à instituição |
| percentual | DECIMAL(5,2) | | Percentual da doação |
| asaas_split_id | VARCHAR(50) | UNIQUE, NOT NULL | ID do split no Asaas |
| status | VARCHAR(20) | NOT NULL | Status: pending, awaiting_credit, done, cancelled, refused, refunded |
| metadata | JSONB | DEFAULT '{}' | Dados adicionais |
| created_at | TIMESTAMP | | Data e hora de criação |
| updated_at | TIMESTAMP | | Data e hora da última atualização |

**Índices:**
- `index_donation_splits_on_asaas_split_id` (único)
- `index_donation_splits_on_status`
- `index_donation_splits_on_donation_id`
- `index_donation_splits_on_institution_id`

**Relacionamento:** Um split pertence a uma doação e a uma instituição.

---

### 6.2.5 Tabela campaigns

Armazena as campanhas de arrecadação de fundos criadas por instituições no tier Pro.

| Coluna | Tipo | Constraints | Descrição |
|--------|------|-------------|-----------|
| id | SERIAL | PRIMARY KEY | Identificador único da campanha |
| institution_id | INTEGER | FOREIGN KEY, NOT NULL | Referência à instituição |
| title | VARCHAR(255) | NOT NULL | Título da campanha |
| description | TEXT | NOT NULL | Descrição detalhada |
| goal_amount | DECIMAL(15,2) | NOT NULL | Valor meta a ser atingido |
| current_amount | DECIMAL(15,2) | DEFAULT 0 | Valor arrecadado até o momento |
| start_date | DATE | NOT NULL | Data de início |
| end_date | DATE | NOT NULL | Data de término |
| cover_image_url | VARCHAR(500) | | URL da imagem de capa |
| status | VARCHAR(20) | NOT NULL | Status: active, paused, closed |
| created_at | TIMESTAMP | | Data e hora de criação |
| updated_at | TIMESTAMP | | Data e hora da última atualização |

**Índices:**
- `index_campaigns_on_status`
- `index_campaigns_on_institution_id_and_status`

**Relacionamento:** Uma campanha pertence a uma instituição.

---

### 6.2.6 Tabela posts

Armazena as publicações de transparência feitas por instituições no feed público.

| Coluna | Tipo | Constraints | Descrição |
|--------|------|-------------|-----------|
| id | SERIAL | PRIMARY KEY | Identificador único do post |
| institution_id | INTEGER | FOREIGN KEY, NOT NULL | Referência à instituição |
| title | VARCHAR(255) | NOT NULL | Título do post |
| content | TEXT | NOT NULL | Conteúdo do post |
| post_type | VARCHAR(20) | NOT NULL | Tipo: update, receipt, report |
| published_at | TIMESTAMP | NOT NULL | Data e hora de publicação |
| created_at | TIMESTAMP | | Data e hora de criação |
| updated_at | TIMESTAMP | | Data e hora da última atualização |

**Índices:**
- `index_posts_on_post_type`
- `index_posts_on_institution_id_and_published_at`

**Relacionamento:** Um post pertence a uma instituição e pode ter múltiplos anexos.

---

### 6.2.7 Tabela post_attachments

Armazena os arquivos anexados a posts de transparência (comprovantes, notas fiscais, etc).

| Coluna | Tipo | Constraints | Descrição |
|--------|------|-------------|-----------|
| id | SERIAL | PRIMARY KEY | Identificador único do anexo |
| post_id | INTEGER | FOREIGN KEY, NOT NULL | Referência ao post |
| file_url | VARCHAR(500) | NOT NULL | URL do arquivo no storage |
| file_type | VARCHAR(50) | NOT NULL | Tipo do arquivo (pdf, image, etc) |
| description | VARCHAR(255) | | Descrição do arquivo |
| created_at | TIMESTAMP | | Data e hora de criação |
| updated_at | TIMESTAMP | | Data e hora da última atualização |

**Relacionamento:** Um anexo pertence a um post.

---

### 6.2.8 Tabela subscriptions

Controla a assinatura de cada instituição (tier gratuito ou Pro).

| Coluna | Tipo | Constraints | Descrição |
|--------|------|-------------|-----------|
| id | SERIAL | PRIMARY KEY | Identificador único da assinatura |
| institution_id | INTEGER | FOREIGN KEY, NOT NULL | Referência à instituição |
| plan | VARCHAR(20) | NOT NULL | Plano: free, pro |
| status | VARCHAR(20) | NOT NULL | Status: active, canceled, expired |
| amount | DECIMAL(10,2) | DEFAULT 0 | Valor mensal da assinatura |
| asaas_subscription_id | VARCHAR(50) | | ID da assinatura no Asaas |
| current_period_start | DATE | | Início do período atual |
| current_period_end | DATE | | Fim do período atual |
| created_at | TIMESTAMP | | Data e hora de criação |
| updated_at | TIMESTAMP | | Data e hora da última atualização |

**Índices:**
- `index_subscriptions_on_institution_id_and_plan`
- `index_subscriptions_on_status`

**Relacionamento:** Uma assinatura pertence a uma instituição (1:1).

---

### 6.2.9 Tabela donation_reports

Armazena os relatórios financeiros gerados por instituições no tier Pro.

| Coluna | Tipo | Constraints | Descrição |
|--------|------|-------------|-----------|
| id | SERIAL | PRIMARY KEY | Identificador único do relatório |
| institution_id | INTEGER | FOREIGN KEY, NOT NULL | Referência à instituição |
| period_start | DATE | NOT NULL | Início do período |
| period_end | DATE | NOT NULL | Fim do período |
| format | VARCHAR(10) | NOT NULL | Formato: pdf, csv |
| file_url | VARCHAR(500) | | URL do arquivo gerado |
| generated_at | TIMESTAMP | | Data e hora de geração |
| total_donations | INTEGER | DEFAULT 0 | Total de doações no período |
| total_amount | DECIMAL(15,2) | DEFAULT 0 | Valor total recebido |
| average_donation | DECIMAL(15,2) | DEFAULT 0 | Média por doação |
| summary | JSONB | DEFAULT '{}' | Resumo estatístico |
| created_at | TIMESTAMP | | Data e hora de criação |
| updated_at | TIMESTAMP | | Data e hora da última atualização |

**Índices:**
- `index_donation_reports_on_institution_id_and_generated_at`

**Relacionamento:** Um relatório pertence a uma instituição.

---

## 6.3 Diagrama Entidade-Relacionamento

O diagrama ER completo está disponível no arquivo:

```
doc/asaas/diagramas/MODELO-DADOS.puml
```

### Resumo dos Relacionamentos

```
users 1────N institutions     (um usuário pode ter várias instituições)
users 1────N donations        (um usuário pode fazer várias doações)
institutions 1────1 subscriptions  (cada instituição tem uma assinatura)
institutions 1────N donation_splits (instituição recebe vários splits)
institutions 1────N campaigns      (instituição cria várias campanhas)
institutions 1────N posts          (instituição publica vários posts)
institutions 1────N reports        (instituição gera vários relatórios)
donations 1────N donation_splits   (doação gera vários splits)
campaigns 1────N donations         (campanha recebe várias doações)
posts 1────N post_attachments      (post tem vários anexos)
```

---

## 6.4 Estratégia de Indexação

O modelo utiliza indexação estratégica para garantir performance nas consultas mais frequentes:

- **Chaves únicas:** email, cnpj, asaas_customer_id, asaas_wallet_id, asaas_payment_id, asaas_split_id
- **Índices de busca:** status (em todas as tabelas com lifecycle), donor_email, institution_id
- **Índices compostos:** (institution_id, status), (institution_id, published_at), (institution_id, generated_at)

---

## 6.5 Integridade Referencial

Todas as chaves estrangeiras possuem constraints de integridade referencial (FOREIGN KEY) configuradas no nível do banco de dados, garantindo que não existam registros órfãos. As operações de cascade são definidas conforme a regra de negócio:

- Exclusão de um usuário → exclui suas instituições
- Exclusão de uma doação → exclui seus splits
- Exclusão de um post → exclui seus anexos

---

## 6.6 Tipos Especiais

### JSONB

As colunas `metadata` (em donations e donation_splits) e `summary` (em donation_reports) utilizam o tipo JSONB do PostgreSQL, permitindo armazenar dados adicionais flexíveis sem necessidade de alteração no schema.

### SERIAL

As colunas de identificação utilizam o tipo SERIAL, que automaticamente gera valores sequenciais inteiros incrementais.

### TIMESTAMP

As colunas de data e hora utilizam TIMESTAMP, que armazena data e hora com precisão de microsegundos e fuso horário UTC.
