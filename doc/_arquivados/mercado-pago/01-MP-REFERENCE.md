# Mercado Pago — Referência Completa (PJ)

> Fontes verificadas em 08/09/2026.
> Base URLs: https://www.mercadopago.com.br/developers/pt/reference

---

## 1. Visão Geral

- **CNPJ:** 10.573.521/0001-91
- **Tipo:** Instituição de Pagamento
- **Conta PJ:** Conta Negócio (para MEI, autônomos e empresas)
- **Rendimento automático:** Sim — saldo da conta rende 100–105% CDI; cofrinhos até 140% CDI

---

## 2. Conta Negócio (PJ)

| Característica | Detalhe |
|----------------|---------|
| Abertura | Gratuita, online, pelo app |
| Mensalidade | Sem mensalidade (para MEI) |
| Cartão | Cartão de crédito vinculado à conta |
| PIX | Enviar e receber, sem tarifa para MEI/EI |
| Point | Maquininha para cartão + QR Code |
| Sistema de gestão | Notas fiscais ilimitadas, relatórios |
| Rendimento | Automático no saldo (100% CDI base) |

**Nota:** Para CNPJs fora de MEI/EI, o Banco Central permite que instituições cobrem tarifas por PIX. A Conta Negócio pode oferecer isenção como diferencial — verificar condições ao abrir a conta.

---

## 3. Rendimento Automático

| Modalidade | Rendimento | Condição |
|------------|------------|----------|
| Dinheiro na conta | 100% CDI | Base, sem movimentação mínima |
| Dinheiro na conta | 105% CDI | Movimentação de R$ 1.000+/mês |
| Cofrinhos | Até 120% CDI | Resgate imediato |
| Cofrinhos | Até 140% CDI | Resgate imediato |

- **IOF:** Isento
- **Liquidez:** Imediata (cofrinhos e saldo)
- **Rendimento:** Diário
- **Consultas via API:** **NÃO disponível** — rendimento é automático, sem controle via API

---

## 4. APIs Disponíveis

### 4.1 API Principal

```
Base URL: https://api.mercadopago.com
Autenticação: Bearer Token (Access Token por aplicação)
```

### 4.2 Endpoints Relevantes

| Recurso | Método | Endpoint | Descrição |
|---------|--------|----------|-----------|
| Criar pagamento | POST | /v1/payments | Criar cobrança (Pix, cartão, boleto) |
| Consultar pagamento | GET | /v1/payments/:id | Status de um pagamento |
| Criar assinatura | POST | /v1/subscriptions | Cobrança recorrente |
| Link de pagamento | POST | /v1/payment_methods | Gerar link para pagamento |
| Webhooks | POST | /v1/webhooks | Receber notificações |

### 4.3 Pagamento via PIX (Checkout Transparente)

```json
POST /v1/payments
{
  "transaction_amount": 100.00,
  "payment_method_id": "pix",
  "payer": {
    "email": "cliente@email.com",
    "identification": {
      "type": "CPF",
      "number": "12345678909"
    }
  }
}
```

**Resposta (pendente):**
```json
{
  "id": 5466310457,
  "status": "pending",
  "status_detail": "pending_waiting_transfer",
  "transaction_data": {
    "qr_code_base64": "...",
    "qr_code": "..."
  }
}
```

### 4.4 Webhooks

```json
POST /v1/webhooks
{
  "url": "https://seudominio.com/webhooks/mp",
  "events": ["payment"]
}
```

**Evento de pagamento:**
```json
{
  "action": "payment.created",
  "api_version": "v1",
  "data": { "id": "5466310457" },
  "date_created": "2026-09-08T10:00:00.000-03:00",
  "id": 123456,
  "live_mode": true,
  "type": "payment",
  "user_id": 123456
}
```

### 4.5 SDKs Oficiais

| Linguagem | Pacote |
|-----------|--------|
| Ruby | `mercadopago-sdk` (gem) |
| Node.js | `mercadopago` |
| Python | `mercadopago` |
| Java | `mercadopago-sdk-java` |

---

## 5. Taxas (Point / Checkout)

### 5.1 Maquininha Point

| Modalidade | Taxa |
|------------|------|
| Débito (Visa/Mastercard) | 0,89% – 1,99% |
| Crédito à vista | 3,08% – 4,99% |
| Crédito 12x | 11,89% |
| PIX | Gratuito |

### 5.2 Checkout Transparente (Online)

| Modalidade | Taxa |
|------------|------|
| PIX | Gratuito (sem tarifa de recebimento) |
| Boleto | Variável |

### 5.3 Nota

- Taxas progressivas por faturamento mensal
- Menor faturamento → maior taxa
- PIX é gratuito para recebimento (sem tarifa na entrada)

---

## 6. Autenticação

### 6.1 Credenciais

| Tipo | Uso |
|------|-----|
| Public Key | Frontend (acesso a meios de pagamento) |
| Access Token | Backend (gerar pagamentos) |
| Client ID / Secret | OAuth (obter tokens) |

### 6.2 Exemplo de Requisição

```bash
curl -H 'Authorization: Bearer YOUR_ACCESS_TOKEN' \
  https://api.mercadopago.com/v1/payments
```

### 6.3 Segurança

- HTTPS obrigatório
- Nunca expor Access Token no frontend
- Usar OAuth para contas de terceiros

---

## 7. Limitações para o Clareo

| Limitação | Impacto |
|-----------|---------|
| Sem API banking (saldo, extrato) | Não é possível consultar saldo via API |
| Sem API de investimentos | Rendimento é automático, sem controle via código |
| Sem sub-contas | Ledgers internos são obrigatórios |
| Pix PJ pode ter tarifa | Verificar condições ao abrir conta |
| Sem SDK Ruby oficial relevante | API REST genérica |

---

## 8. Vantagens para o Clareo

| Vantagem | Detalhe |
|----------|---------|
| Rendimento automático | 100–105% CDI sem fazer nada |
| Cofrinhos | Até 140% CDI com resgate imediato |
| PIX gratuito (recebimento) | Sem tarifa de entrada |
| Conta sem mensalidade | Para MEI |
| Webhooks | Notificação de pagamentos |
| Checkout Transparente | Integração com PIX direto no site |

---

## 9. Links Úteis

| Recurso | URL |
|---------|-----|
| Developers | https://www.mercadopago.com.br/developers |
| API Reference | https://www.mercadopago.com.br/developers/pt/reference |
| Credenciais | https://www.mercadopago.com.br/developers/pt/docs/your-integrations/credentials |
| Checkout Bricks | https://www.mercadopago.com.br/developers/pt/docs/checkout-bricks/overview |
| MCP Server | https://github.com/mercadopago/mcp-server |
| Conta Negócio | https://www.mercadopago.com.br/conta-negocio |
| Rendimento | https://www.mercadopago.com.br/blog/como-funciona-conta-remunerada-mercado-pago |

---

*Documento gerado a partir de fontes públicas do Mercado Pago em 08/09/2026.*
