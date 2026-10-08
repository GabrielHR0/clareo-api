# Inter API — Referência Completa

## Links Oficiais

| Recurso | Link |
|---------|------|
| Portal do Desenvolvedor | https://developers.inter.co |
| API Banking | https://developers.inter.co/references/banking |
| API Pix | https://developers.inter.co/references/pix |
| API Pix Automático | https://developers.inter.co/references/pix-automatico |
| API Cobrança (Boleto com Pix) | https://developers.inter.co/references/cobranca-bolepix |
| Webhooks | https://developers.inter.co/docs/webhooks |
| Sandbox | https://developers.inter.co/sandbox |
| SDK Java | https://developers.inter.co/docs/sdks/sdk-java |
| SDK C# | https://developers.inter.co/docs/sdks/sdk-intro |
| Changelog | https://developers.inter.co/changelog |
| Comunidade | https://comunidade.inter.co/developers |
| Conta PJ | https://www.bancointer.com.br/empresas/conta-digital/pessoa-juridica/ |
| Investimentos PJ | https://inter.co/empresas/investimento-empresarial/ |
| Tabela de Tarifas PJ | https://static.bancointer.com.br/site/tabela-tarifas/06828f37a7464f8ab3eb4e5571586214_tabela-de-tarifas-pj-maio.pdf |
| Central de Ajuda | https://ajuda.inter.co |
| Suporte | 3003 4070 (capitais) / 0800 940 0007 (demais) |

---

## Conta PJ Digital

### Características

| Item | Detalhe |
|------|---------|
| Abertura | 100% digital, gratuita |
| Tipos societários | MEI, EIRELI/EI, LTDA, SA, Condomínios |
| PIX envio | Gratuito e ilimitado |
| PIX recebimento (chave/estático) | Gratuito |
| Cartão crédito/débito | Sem anuidade, programa Inter Loop |
| Boleto (cota mensal) | Gratuito (acima da cota: R$0,99 via Pix, R$2,49 digitável) |
| TED | Gratuito (cota mensal) |
| Cheque especial | Limite extra na conta |
| Investimentos | CDB, Fundos, Debêntures (pelo Super App, sem API) |
| Folha de pagamento | Disponível |
| Antecipação de recebíveis | Disponível |
| Internet Banking | Completo |
| App | Super App Inter Empresas |

### Perfis de Relacionamento

| Perfil | Boleto/mês | Benefícios |
|--------|------------|------------|
| Digital | 30 | Básico |
| Pro | 60 | Advisor/Consultor |
| Enterprise | 100 | Investimentos exclusivos, atendimento via WhatsApp |

---

## Autenticação

### OAuth 2.0

Todas as APIs usam autenticação OAuth 2.0 com certificado digital.

**Fluxo:**
1. Gerar certificado (baixado no portal do desenvolvedor)
2. Obter token via OAuth
3. Usar token nos headers das requisições

**Headers obrigatórios:**
```
Authorization: Bearer <access_token>
x-inter-conta-digital-pj: <codigo_conta>
```

**Certificado:** validade de 1 ano.

---

## API Banking

**Referência:** https://developers.inter.co/references/banking

### Endpoints

| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/banking/v2/saldos` | GET | Consulta saldos |
| `/banking/v2/extratos` | GET | Consulta extrato por período |
| `/banking/v2/pagamentos` | POST | Incluir pagamento (boleto/DARF) |
| `/banking/v2/pagamentos/{id}` | GET | Consultar pagamento |
| `/banking/v2/pagamentos/lote` | POST | Pagamento em lote |
| `/banking/v2/darf` | POST | Incluir DARF |
| `/banking/v2/darf/{id}` | GET | Consultar DARF |
| `/banking/v2/comprovantes/{id}` | GET | Exportar comprovante PDF |
| `/banking/v2/extratos/exportar` | GET | Exportar extrato PDF |

### Consulta de Saldo

```http
GET /banking/v2/saldos
Authorization: Bearer <token>
x-inter-conta-digital-pj: <conta>
```

Response:
```json
{
  "saldo": 15000.00,
  "disponivel": 15000.00,
  "bloqueado": 0.00
}
```

### Consulta de Extrato

```http
GET /banking/v2/extratos?dataInicio=2026-01-01&dataFim=2026-01-31
Authorization: Bearer <token>
x-inter-conta-digital-pj: <conta>
```

### Pagamento com Código de Barras

```http
POST /banking/v2/pagamentos
Authorization: Bearer <token>
x-inter-conta-digital-pj: <conta>
Content-Type: application/json

{
  "codigoBarras": "23793.38128 60000.000003 00000.000400 1 84320000023905",
  "dataPagamento": "2026-09-10",
  "valorPagamento": 239.05,
  "seuNumero": "pedido-123"
}
```

---

## API Pix

**Referência:** https://developers.inter.co/references/pix

### Endpoints

| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/pix/v2/cob` | POST | Criar cobrança imediata |
| `/pix/v2/cob/{txid}` | GET | Consultar cobrança |
| `/pix/v2/cob/{txid}` | PUT | Revisar cobrança |
| `/pix/v2/cob` | GET | Listar cobranças |
| `/pix/v2/cobv` | POST | Criar cobrança com vencimento |
| `/pix/v2/cobv/{txid}` | GET | Consultar cobrança com vencimento |
| `/pix/v2/cobv/{txid}` | PUT | Revisar cobrança com vencimento |
| `/pix/v2/cobv` | GET | Listar cobranças com vencimento |
| `/pix/v2/pix/{e2eId}` | GET | Consultar Pix recebido |
| `/pix/v2/pix` | GET | Listar Pix recebidos |
| `/pix/v2/devolucao/{e2eId}/{id}` | POST | Solicitar devolução |
| `/pix/v2/devolucao/{e2eId}/{id}` | GET | Consultar devolução |
| `/pix/v2/loc` | GET | Listar locations |

### Criar Cobrança Imediata (QR Code)

```http
POST /pix/v2/cob
Authorization: Bearer <token>
x-inter-conta-digital-pj: <conta>
Content-Type: application/json

{
  "calendario": {
    "expiracao": 3600
  },
  "valor": {
    "original": 100.00
  },
  "chave": "cnpj-do-clareo",
  "solicitacaoPagador": "Doação - Instituição X"
}
```

Response:
```json
{
  "loc": { "id": 123456 },
  "txid": "abc123",
  "cobv": null,
  "-calendario": {
    "criacao": "2026-09-08T19:30:00Z",
    "expiracao": 3600
  },
  "valor": {
    "original": "100.00"
  },
  "chave": "cnpj-do-clareo",
  "status": "ATIVA",
  "pixCopiaECola": "00020126..."
}
```

### Criar Cobrança com Vencimento

```http
POST /pix/v2/cobv
Authorization: Bearer <token>
x-inter-conta-digital-pj: <conta>
Content-Type: application/json

{
  "calendario": {
    "dataDeVencimento": "2026-09-15",
    "validadeAposVencimento": 3
  },
  "valor": {
    "original": 500.00,
    "multa": { "modalidade": 1, "valorPerc": "2.00" },
    "juros": { "modalidade": 1, "valorPerc": "1.00" }
  },
  "chave": "cnpj-do-clareo",
  "solicitacaoPagador": "Mensalidade - Instituição Y"
}
```

### Consultar Pix Recebidos

```http
GET /pix/v2/pix?dataInicio=2026-09-01&dataFim=2026-09-08
Authorization: Bearer <token>
x-inter-conta-digital-pj: <conta>
```

### Webhook Pix

O Inter envia notificação quando um Pix é recebido:

```json
{
  "pix": [
    {
      "endToEndId": "E20018183202608011619R0GjOKSrhlO",
      "txid": "abc123",
      "valor": "100.00",
      "horario": "2026-09-08T19:35:00Z",
      "pagador": {
        "nome": "João da Silva",
        "cpf": "12345678900"
      }
    }
  ]
}
```

---

## API Pix Automático

**Referência:** https://developers.inter.co/references/pix-automatico

Cria cobranças recorrentes com débito automático.

### Endpoints

| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/pix/v2/pix-automatico` | POST | Criar contrato de Pix Automático |
| `/pix/v2/pix-automatico/{id}` | GET | Consultar contrato |
| `/pix/v2/pix-automatico` | GET | Listar contratos |
| `/pix/v2/pix-automatico/{id}` | DELETE | Cancelar contrato |

### Criar Contrato

```http
POST /pix/v2/pix-automatico
Authorization: Bearer <token>
x-inter-conta-digital-pj: <conta>
Content-Type: application/json

{
  "valorTransacao": 99.90,
  "dataInicio": "2026-09-10",
  "dataFim": "2027-09-10",
  "frequencia": "MENSAL",
  "chave": "chave-pix-do-pagador",
  "descricao": "Assinatura - Serviço X"
}
```

---

## API Cobrança (Boleto com Pix)

**Referência:** https://developers.inter.co/references/cobranca-bolepix

### Endpoints

| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/cobranca/v3/cobrancas` | POST | Emitir cobrança |
| `/cobranca/v3/cobrancas` | GET | Listar cobranças |
| `/cobranca/v3/cobrancas/{id}` | GET | Consultar cobrança |
| `/cobranca/v3/cobrancas/{id}` | PATCH | Editar cobrança |
| `/cobranca/v3/cobrancas/{id}/pdf` | GET | Exportar PDF |
| `/cobranca/v3/cobrancas/{id}/cancelamento` | POST | Cancelar cobrança |
| `/cobranca/v3/cobrancas/summary` | GET | Resumo de cobranças |

### Emitir Cobrança

```http
POST /cobranca/v3/cobrancas
Authorization: Bearer <token>
x-inter-conta-digital-pj: <conta>
Content-Type: application/json

{
  "seuNumero": "pedido-456",
  "valorNominal": 250.00,
  "dataVencimento": "2026-09-20",
  "desconto": { "valor": 10.00 },
  "multa": { "valor": 5.00 },
  "juros": { "valor": 2.50 },
  "mensagemAvulsa": "Referente ao pedido #456"
}
```

### Cancelar Cobrança

```http
POST /cobranca/v3/cobrancas/{id}/cancelamento
Authorization: Bearer <token>
x-inter-conta-digital-pj: <conta>
```

---

## Webhooks

**Referência:** https://developers.inter.co/docs/webhooks

### O que são

Webhooks permitem que o Inter envie atualizações em tempo real para o seu sistema.

### Eventos Disponíveis

| API | Eventos |
|-----|---------|
| Pix | Cobrança paga, Pix recebido, devolução |
| Cobrança | Boleto pago, cancelado |
| Pix Automático | Contrato quitado, falha |

### Criar Webhook

```http
PUT /webhook/v1/{api}
Authorization: Bearer <token>
x-inter-conta-digital-pj: <conta>
Content-Type: application/json

{
  "webhookUrl": "https://api.clareo.com/webhooks/inter",
  "x-inter-conta-digital-pj": "<conta>"
}
```

### Headers Recebidos

```
x-inter-signature: <hmac-sha256>
x-inter-timestamp: <unix-timestamp>
```

### Validação HMAC

```ruby
def verify_webhook(signature:, body:, timestamp:)
  secret = ENV['INTER_WEBHOOK_SECRET']
  payload = timestamp + body
  expected = OpenSSL::HMAC.hexdigest('SHA256', secret, payload)
  Rack::Utils.secure_compare(expected, signature)
end
```

---

## Taxas

### Conta PJ

| Serviço | Taxa | Fonte |
|---------|------|-------|
| Abertura de conta | Grátis | Inter |
| Manutenção | Grátis | Inter |
| PIX envio | Grátis | Inter |
| PIX recebimento (chave/estático) | Grátis | Wise/Inter |
| PIX recebimento (QR dinâmico) | 0,9% (mín R$0,10, máx R$1,50) | Wise (02/2026) |
| PIX recebimento (com vencimento) | 0,99% (mín R$0,10, máx R$1,99) | Wise (02/2026) |
| PIX Saque/Troco | R$6,40 | Wise (02/2026) |
| PIX Automático (recebido) | R$0,50 por transação | Inter (ajuda) |
| Boleto (na cota) | Grátis | Inter |
| Boleto (acima da cota) | R$0,99 (Pix) / R$2,49 (digitável) | Inter |
| TED (na cota) | Grátis | Inter |
| Cartão crédito | Sem anuidade | Inter |
| Cartão débito | Sem anuidade | Inter |

### Investimentos PJ

| Investimento | Rendimento | Mínimo | FGC | API |
|--------------|------------|--------|-----|-----|
| CDB pós-fixado | ~100% CDI | R$100 | Sim, até R$250k/CNPJ | ❌ |
| CDB prefixado | ~12,25% a.a. | R$5.000 | Sim | ❌ |
| Fundos | Variável | R$100 | Não | ❌ |
| Debêntures | Variável | Variável | Não | ❌ |

> **Nota:** Investimentos são acessíveis apenas pelo Super App ou Internet Banking. Não existe API pública para investimentos.

---

## Automações Possíveis

| Automação | Como fazer | API disponível |
|-----------|------------|----------------|
| Receber doação via PIX | API Pix → criar cobrança → webhook | ✅ |
| Consultar saldo | API Banking → GET /saldos | ✅ |
| Consultar extrato | API Banking → GET /extratos | ✅ |
| Enviar PIX para instituição | API Pix Pagamento (via Banking) | ✅ |
| Cobrança recorrente | API Pix Automático | ✅ |
| Emitir boleto | API Cobrança | ✅ |
| Pagamento em lote | API Banking | ✅ |
| Relatórios/PDF | API Banking | ✅ |
| Notificações em tempo real | Webhooks | ✅ |
| Investir em CDB automaticamente | ❌ Não tem API | ❌ |
| Criar sub-contas | ❌ Não tem API | ❌ |
| Gerenciar múltiplas chaves | ❌ Não documentado na API | ❌ |

---

## Segurança

| Camada | Detalhe |
|--------|---------|
| Autenticação | OAuth 2.0 com certificado digital |
| Certificado | Validade de 1 ano |
| Webhooks | Assinatura HMAC-SHA256 |
| Conexão | TLS obrigatório |
| Controles | Gestão de acessos e aprovações no app |
| Compliance | KYC/AML na abertura da conta |

---

## SDKs

| Linguagem | Link |
|-----------|------|
| Java | https://developers.inter.co/docs/sdks/sdk-java |
| C# | https://developers.inter.co/docs/sdks/sdk-intro |

> **Nota:** Não existe SDK oficial para Ruby. A integração deve ser feita via HTTP direto.

---

## Limitações

| Limitação | Detalhe |
|-----------|---------|
| Apenas PJ | APIs disponíveis somente para clientes pessoa jurídica |
| Sem SDK Ruby | Integração via HTTP direto |
| Sem API de investimentos | CDB/Fundos são manuais pelo app |
| Sem sub-contas | Não é possível criar contas filhas via API |
| Sem multi-tenant nativo | Uma conta PJ, ledger interno necessário |
| Certificado | Renovação anual manual |

---

## Validação

| Informação | Fonte | Data verificada |
|------------|-------|-----------------|
| Pix gratuito para PJ | Wise/Blog Inter | Mar 2026 |
| Taxas Pix QR dinâmico | Wise (tabela) | Fev 2026 |
| API Banking disponível | developers.inter.co | Set 2026 |
| API Pix disponível | developers.inter.co | Set 2026 |
| Investimentos sem API | inter.co/empresas | Set 2026 |
| CDB ~100% CDI | Meelion/QuantoRende | Set 2026 |
