# 9. Diagramas de Implantação do Sistema

## 9.1 Visão Geral

O diagrama de implantação do Clareo representa a arquitetura física do sistema, incluindo os nós (servidores, dispositivos), componentes de software e comunicações entre eles. O sistema é projetado para execução em ambiente cloud, utilizando serviços gerenciados para garantir disponibilidade, escalabilidade e segurança.

---

## 9.2 Arquitetura Física

### 9.2.1 Dispositivos do Usuário

O usuário interage com o sistema através de dois dispositivos principais:

**Navegador Web** — Utilizado por doadores, instituições e administradores para acessar a plataforma. Comunica com a API REST do Clareo via HTTPS.

**App Bancário** — Utilizado pelo doador para efetuar pagamentos PIX. Comunica diretamente com o SPI (Sistema de Pagamentos Instantâneos) do Banco Central.

---

### 9.2.2 Servidor Clareo

O servidor principal do Clareo é composto por dois containers Docker executando em um ambiente cloud (AWS ou Heroku):

**Container Docker:**
- **Rails API (Puma):** Servidor web que processa requisições HTTP. Executa os controllers e services do sistema.
- **Background Jobs (Sidekiq):** Processador de tarefas assíncronas. Executa jobs de doação, relatórios e webhooks.

**Redis:**
- **Cache:** Armazena dados temporários para acelerar consultas.
- **Queue:** Fila de mensagens para o Sidekiq processar jobs assíncronos.

---

### 9.2.3 Banco de Dados

O banco de dados é executado em um serviço gerenciado (AWS RDS), garantindo backup automático, replicação e alta disponibilidade.

**PostgreSQL 15:**
- users — Usuários do sistema
- institutions — Instituições parceiras
- donations — Doações recebidas
- donation_splits — Rateio entre instituições
- campaigns — Campanhas de arrecadação
- posts — Publicações de transparência
- subscriptions — Assinaturas
- donation_reports — Relatórios gerados

---

### 9.2.4 Storage

Arquivos estáticos são armazenados em um serviço de object storage (AWS S3):

**Bucket "clareo-uploads":**
- `attachments/` — Comprovantes e documentos anexados a posts
- `reports/` — Relatórios financeiros gerados (PDF/CSV)
- `campaigns/` — Imagens de capa das campanhas

---

### 9.2.5 CDN

Conteúdo estático e assets são servidos através de uma CDN (CloudFront), melhorando a performance e reduzindo a latência para usuários globais.

---

### 9.2.6 Asaas (PSP)

O Asaas é o sistema externo que processa pagamentos e splits:

**API v3:** Interface REST para criação de cobranças, clientes, subcontas e assinaturas.

**Webhooks:** Notificações enviadas ao Clareo quando ocorrem eventos (pagamento recebido, split concluído, etc).

**PIX Engine:** Motor de processamento de PIX que se comunica com o SPI do Banco Central.

---

### 9.2.7 Banco Central (SPI)

O Sistema de Pagamentos Instantâneos (SPI) é a infraestrutura do Banco Central que processa transferências PIX instantâneas.

---

## 9.3 Comunicações

| Origem | Destino | Protocolo | Porta | Descrição |
|--------|---------|-----------|-------|-----------|
| Navegador | CDN | HTTPS | 443 | Assets estáticos |
| CDN | Rails API | HTTPS | 443 | Requisições API |
| Rails API | PostgreSQL | TCP | 5432 | Queries SQL |
| Rails API | Redis | TCP | 6379 | Cache e filas |
| Rails API | Asaas API | HTTPS | 443 | Integração pagamentos |
| Rails API | S3 | HTTPS | 443 | Upload/download arquivos |
| Asaas WH | Rails API | HTTPS | 443 | Webhooks |
| Asaas API | SPI | Interno | - | Processamento PIX |
| App Bancário | SPI | Interno | - | Pagamento PIX |

---

## 9.4 Diagramas

### Diagrama de Implantação — Visão Geral

**Arquivo:** `implantacao/01-VISAO-GERAL.puml`

Representa a arquitetura de alto nível, mostrando os principais nós e suas conexões.

### Diagrama de Implantação — Detalhado

**Arquivo:** `implantacao/02-DETALHADO.puml`

Representa a arquitetura detalhada, incluindo componentes internos de cada nó, como controllers, jobs, tabelas do banco e pastas do storage.

---

## 9.5 Stack Tecnológica

| Camada | Tecnologia | Justificativa |
|--------|------------|---------------|
| Frontend | React/Vue | SPA moderna, responsiva |
| API | Ruby on Rails 8 | Framework produtivo, maduro |
| Servidor Web | Puma | Servidor concorrente para Rails |
| Background Jobs | Sidekiq | Processamento assíncrono confiável |
| Cache/Filas | Redis | Performance e fila de jobs |
| Banco de Dados | PostgreSQL 15 | robustez, JSONB, indexação |
| Storage | AWS S3 | Object storage escalável |
| CDN | CloudFront | Distribuição global de conteúdo |
| PSP | Asaas | Split payment, PIX, subcontas |
| Deploy | Docker | Containerização e portabilidade |
| Hospedagem | AWS/Heroku | Cloud gerenciada |

---

## 9.6 Fluxo de Dados

### Fluxo de uma Doação

```
1. Doador acessa Clareo (HTTPS → CDN → Rails API)
2. Doador seleciona instituição e valor
3. Rails API cria pagamento no Asaas (HTTPS)
4. Asaas retorna QR Code PIX
5. Doador paga via App Bancário (→ SPI)
6. SPI processa PIX instantaneamente
7. Asaas envia webhook para Rails API
8. Rails API atualiza status no PostgreSQL
9. Asaas processa split automaticamente
10. Instituição recebe crédito na subconta
```

### Fluxo de um Webhook

```
1. Asaas envia webhook (HTTPS → Rails API)
2. WebhooksController verifica assinatura
3. WebhookService identifica evento
4. Service atualiza registro no PostgreSQL
5. Rails API retorna 200 OK
```

---

## 9.7 Segurança

| Camada | Medida |
|--------|--------|
| Transporte | TLS 1.3 (HTTPS) em todas as comunicações |
| Autenticação | JWT + bcrypt para senhas |
| Banco de Dados | Credenciais em variáveis de ambiente |
| API Keys | Armazenadas em ENV, nunca no código |
| Webhooks | Verificação de assinatura HMAC |
| Storage | ACLs de acesso, URLs temporárias |
| Rede | Security groups, WAF (opcional) |

---

## 9.8 Escalabilidade

| Componente | Estratégia |
|------------|------------|
| Rails API | Horizontal scaling (múltiplos containers) |
| Sidekiq | Múltiplos workers |
| PostgreSQL | Read replicas, connection pooling |
| Redis | Cluster mode (opcional) |
| S3 | Infinitamente escalável |
| CDN | Distribuição automática |

---

## 9.9 Monitoramento

| Ferramenta | Uso |
|------------|-----|
| New Relic/Datadog | APM (Application Performance Monitoring) |
| Sentry | Error tracking |
| PgHero | Monitoramento PostgreSQL |
| Sidekiq Web UI | Monitoramento de jobs |
| AWS CloudWatch | Métricas de infraestrutura |
