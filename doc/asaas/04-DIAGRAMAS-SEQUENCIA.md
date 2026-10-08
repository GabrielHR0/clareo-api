# 4. Diagramas de Sequência do Sistema

## Visão Geral

Esta seção apresenta os diagramas de sequência para os principais casos de uso do sistema Clareo. Cada diagrama ilustra a troca de mensagens entre os atores, as interfaces do sistema, os serviços de negócio e as fontes de dados durante a execução de um cenário específico.

Os diagramas seguem a notação UML padrão, com linhas de vida representando os objetos participantes e setas representando as mensagens trocadas entre eles. Comentários e grupos são utilizados para indicar alternativas e fluxos paralelos.

---

## 4.1 Cadastrar Conta

**Caso de Uso:** Um novo usuário (doador, instituição ou admin) cria sua conta no sistema.

**Ator:** Usuário (Doador, Instituição ou Admin)

**Fluxo:**
1. O Usuário preenche o formulário de cadastro com nome, email, senha e tipo de perfil (role).
2. O Frontend envia uma requisição POST para o endpoint `/api/v1/auth/register`.
3. O AuthController recebe os dados e invoca o UserService para criar o usuário.
4. O UserService valida os dados, gera o hash da senha com bcrypt e insere o registro no banco PostgreSQL.
5. O AuthService gera um token JWT com o identificador do usuário.
6. O sistema retorna o token e os dados do usuário criado.

**Arquivo:** `sequencias/01-CADASTRAR-CONTA.puml`

---

## 4.2 Fazer Login

**Caso de Uso:** Um usuário existente se autentica no sistema.

**Ator:** Usuário

**Fluxo:**
1. O Usuário preenche email e senha.
2. O Frontend envia uma requisição POST para `/api/v1/auth/login`.
3. O AuthController busca o usuário por email no banco de dados.
4. O sistema verifica se a senha fornecida corresponde ao hash armazenado.
5. Se a senha estiver correta, gera um token JWT e retorna os dados do usuário.
6. Se a senha estiver incorreta, retorna erro 401 Unauthorized.

**Arquivo:** `sequencias/02-FAZER-LOGIN.puml`

---

## 4.3 Doar via PIX

**Caso de Uso:** Um doador realiza uma contribuição financeira para uma ou mais instituições.

**Ator:** Doador

**Fluxo:**
1. O Doador seleciona a(s) instituição(ões) e define o valor da doação.
2. O Frontend envia uma requisição POST para `/api/v1/donations`.
3. O DonationService busca as instituições selecionadas e calcula os splits (percentuais ou valores fixos).
4. O AsaasService cria uma cobrança no Asaas com os splits configurados.
5. O Asaas retorna o QR Code PIX e o código copia-e-cola.
6. O sistema salva a doação com status `pending` e os splits correspondentes.
7. O Doador paga via PIX usando o código gerado.
8. O Asaas envia um webhook `PAYMENT_RECEIVED` notificando o pagamento.
9. O Clareo atualiza o status da doação para `received`.
10. Quando o split é processado, o Asaas envia `PAYMENT_SPLIT_DONE`.
11. O Clareo atualiza o status para `split_done`.

**Arquivo:** `sequencias/03-DOAR-PIX.puml`

---

## 4.4 Ver Doações

**Caso de Uso:** Uma instituição visualiza as doações recebidas.

**Ator:** Instituição

**Fluxo:**
1. A Instituição acessa o painel de doações.
2. O Frontend envia uma requisição GET para `/api/v1/donations`.
3. O DonationsController verifica o JWT e a role do usuário.
4. O sistema busca no banco as doações vinculadas à instituição, com paginação.
5. Retorna a lista de doações com valores, status e dados dos doadores.

**Arquivo:** `sequencias/04-VER-DOACOES.puml`

---

## 4.5 Criar Campanha

**Caso de Uso:** Uma instituição cria uma campanha de arrecadação de fundos.

**Ator:** Instituição

**Pré-condição:** Instituição deve possuir assinatura Pro ativa.

**Fluxo:**
1. A Instituição preenche o formulário com título, descrição, valor meta e prazo.
2. O Frontend envia POST para `/api/v1/campaigns`.
3. O CampaignsController verifica o JWT e invoca o CampaignService.
4. O CampaignService verifica se a instituição possui assinatura Pro ativa.
5. Se sim, cria a campanha com status `active`.
6. Se não, retorna erro 403 Forbidden.

**Arquivo:** `sequencias/05-CRIAR-CAMPANHA.puml`

---

## 4.6 Postar Atualização (Transparência)

**Caso de Uso:** Uma instituição publica uma atualização no feed de transparência.

**Ator:** Instituição

**Pré-condição:** Instituição deve possuir assinatura Pro ativa.

**Fluxo:**
1. A Instituição preenche o post com título, conteúdo e tipo (update, receipt, report).
2. O Frontend envia POST para `/api/v1/posts`.
3. O PostsController verifica a assinatura Pro.
4. O PostService cria o post com `published_at`等于 a data atual.
5. Para anexar comprovantes, a instituição envia arquivos via POST para `/api/v1/posts/:id/attachments`.
6. Os arquivos são uploadados para o storage (S3/CloudFlare) e registrados no banco.

**Arquivo:** `sequencias/06-POSTAR-ATUALIZACAO.puml`

---

## 4.7 Gerar Relatório

**Caso de Uso:** Uma instituição gera um relatório financeiro de doações.

**Ator:** Instituição

**Pré-condição:** Instituição deve possuir assinatura Pro ativa.

**Fluxo:**
1. A Instituição define o período e o formato (PDF ou CSV).
2. O Frontend envia POST para `/api/v1/reports`.
3. O ReportService verifica a assinatura Pro.
4. O sistema busca no banco os dados de doações do período.
5. Calcula totais, médias e estatísticas.
6. Gera o arquivo no formato solicitado.
7. Faz upload do arquivo para o storage.
8. Salva o registro do relatório no banco com URL de download.
9. Para baixar, o Frontend solicita GET para `/api/v1/reports/:id/download`.
10. O sistema retorna redirecionamento para a URL do arquivo.

**Arquivo:** `sequencias/07-GERAR-RELATORIO.puml`

---

## 4.8 Gerenciar Assinatura

**Caso de Uso:** Uma instituição visualiza, faz upgrade ou cancela sua assinatura.

**Ator:** Instituição

**Fluxo (Ver Plano):**
1. A Instituição acessa as configurações.
2. O Frontend envia GET para `/api/v1/subscription`.
3. O sistema retorna os dados da assinatura atual.

**Fluxo (Upgrade para Pro):**
1. A Instituição clica em "Upgrade para Pro".
2. O Frontend envia POST para `/api/v1/subscription/upgrade`.
3. O SubscriptionService cria uma assinatura recorrente no Asaas.
4. O Asaas retorna URL de pagamento.
5. O sistema atualiza a assinatura com status `pending`.
6. Quando a instituição paga, o Asaas envia webhook `SUBSCRIPTION_CREATED`.
7. O sistema atualiza o status para `active`.

**Arquivo:** `sequencias/08-GERENCIAR-ASSINATURA.puml`

---

## 4.9 Criar Subconta (Admin)

**Caso de Uso:** Um administrador cadastra uma nova instituição no sistema.

**Ator:** Admin

**Fluxo:**
1. O Admin preenche os dados da instituição (nome, CNPJ, email, chave PIX).
2. O Frontend envia POST para `/api/v1/institutions`.
3. O InstitutionsController verifica a role de admin.
4. O InstitutionService cria o cliente no Asaas via API.
5. Cria uma subconta no Asaas para receber splits.
6. Cria o usuário e a instituição no banco de dados.
7. Cria uma assinatura gratuita (tier free) para a instituição.
8. Retorna os dados da instituição cadastrada.

**Arquivo:** `sequencias/09-CRIAR-SUBCONTA.puml`

---

## 4.10 Processar Webhook

**Caso de Uso:** O sistema recebe e processa notificações do Asaas.

**Ator:** Asaas (sistema externo)

**Fluxo:**
1. O Asaas envia uma requisição POST para `/api/v1/webhooks/asaas`.
2. O WebhooksController verifica a assinatura da requisição.
3. O WebhookService identifica o tipo de evento.
4. Para `PAYMENT_RECEIVED`: atualiza o status da doação para `received`.
5. Para `PAYMENT_SPLIT_DONE`: atualiza o status para `split_done`.
6. Para `SUBSCRIPTION_CREATED`: ativa a assinatura da instituição.
7. Para `PAYMENT_SPLIT_DIVERGENCE_BLOCK`: registra log de alerta.
8. Retorna 200 OK para o Asaas.

**Arquivo:** `sequencias/10-PROCESSAR-WEBHOOK.puml`

---

## Resumo dos Diagramas

| # | Diagrama | Caso de Uso | Ator Principal |
|---|----------|-------------|----------------|
| 01 | Cadastrar Conta | Registro de usuário | Usuário |
| 02 | Fazer Login | Autenticação | Usuário |
| 03 | Doar via PIX | Doação com split | Doador |
| 04 | Ver Doações | Consulta de doações | Instituição |
| 05 | Criar Campanha | Criação de campanha | Instituição |
| 06 | Postar Atualização | Transparência | Instituição |
| 07 | Gerar Relatório | Relatório financeiro | Instituição |
| 08 | Gerenciar Assinatura | Upgrade/cancelamento | Instituição |
| 09 | Criar Subconta | Cadastro de instituição | Admin |
| 10 | Processar Webhook | Notificações Asaas | Asaas |

Todos os diagramas estão disponíveis na pasta `doc/asaas/diagramas/sequencias/`.
