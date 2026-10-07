# Clareo — Autenticação JWT

> Bearer token HS256, expiração de 24 horas, blacklist em Redis.

## Papéis

| Papel | Alcance |
|-------|---------|
| `donor` | apenas as próprias doações |
| `institution_admin` | instituições que administra |
| `platform_admin` | tudo, mais endpoints operacionais |

Uma assinatura por usuário; um usuário administra de 1 a N instituições.
Papel é do **usuário**, não da instituição.

## Variáveis

```bash
# .env
JWT_SECRET=minimo_32_bytes_aleatorios
JWT_EXPIRATION=86400
```

`JWT_SECRET` com menos de 32 bytes é trivialmente forçável em brute force de
HMAC. `bin/rails secret` gera um adequate.

## Emissão

```ruby
# app/adapters/primary/auth/token_encoder.rb
class Auth::TokenEncoder
  ALGORITHM = "HS256"

  def initialize(secret: ENV.fetch("JWT_SECRET"), expiration: Integer(ENV.fetch("JWT_EXPIRATION", 86_400)))
    @secret = secret
    @expiration = expiration
  end

  def call(user)
    now = Time.now.to_i
    payload = {
      sub: user.id.to_s,
      email: user.email,
      role: user.role,
      iat: now,
      exp: now + @expiration
    }

    JWT.encode(payload, @secret, ALGORITHM)
  end
end
```

### O Que Vai no Token

`sub`, `email`, `role`, `iat`, `exp`.

O papel **pode** ir no token — economiza uma consulta por requisição, e o
descarte é imperfeito: um usuário rebaixado de `platform_admin` continua com
token válido até expirar. Para o volume deste produto, 24 horas é aceitável. Se
vir a incomodar, versione o token e invalide por versão.

O `institution_id` **não** vai no token. São N por usuário e mudam com
frequência; manter no token exigiria reemissão a cada instituição nova.

## Validação

```ruby
# app/adapters/primary/auth/token_decoder.rb
class Auth::TokenDecoder
  ALGORITHM = "HS256"

  def initialize(secret: ENV.fetch("JWT_SECRET"))
    @secret = secret
  end

  def call(token)
    payload, = JWT.decode(token, @secret, true, algorithm: ALGORITHM)
    payload
  rescue JWT::ExpiredSignature
    raise Auth::ExpiredError
  rescue JWT::DecodeError
    raise Auth::InvalidError
  end
end
```

**`algorithm: ALGORITHM` é obrigatório.** Sem ele o JWT aceita o algoritmo
escrito no próprio token, e `alg: none` passa. É uma vulnerabilidade real, não
teórica.

## Autenticação e Autorização

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  before_action :authenticate_user!

  rescue_from DomainError do |error|
    render json: { error: error.message, code: error.code }, status: :unprocessable_entity
  end

  private

  def authenticate_user!
    token = bearer_token
    return unauthorized("Token não fornecido") if token.nil?

    payload = Auth::TokenDecoder.new.call(token)
    return unauthorized("Token expirado") if payload.nil?

    return unauthorized("Token revogado") if revoked?(payload["jti"])

    @current_user = User.find_by(id: payload["sub"])
    return unauthorized("Usuário não encontrado") if @current_user.nil?
  rescue Auth::ExpiredError
    unauthorized("Token expirado")
  rescue Auth::InvalidError
    unauthorized("Token inválido")
  end

  # Autorização é sobre o RECURSO, não sobre o token.
  def authorize_institution!(institution)
    return if current_user.platform_admin?
    return if current_user.owns?(institution)

    render json: { error: "Não autorizado" }, status: :forbidden
  end

  def require_platform_admin!
    return if current_user&.platform_admin?

    render json: { error: "Não autorizado" }, status: :forbidden
  end

  def bearer_token
    request.headers["Authorization"]&.split(" ")&.last
  end

  def revoked?(jti)
    return false if jti.nil?

    Rails.cache.exist?("jwt:revoked:#{jti}")
  end

  def unauthorized(message)
    render json: { error: message }, status: :unauthorized
  end
end
```

Token válido **não** implica autorização. `institution_admin` não lê a doação de
outra instituição só porque tem JWT válido.

## Login

```ruby
# app/adapters/primary/api/v1/auth_controller.rb
module Api::V1
  class AuthController < ApplicationController
    skip_before_action :authenticate_user!, only: %i[register]

    def login
      user = User.find_by(email: params[:email].to_s.downcase)

      # Sempre executa o bcrypt, mesmo sem usuário, para não vazar por timing
      # quem tem conta.
      valid = user&.authenticate(params[:password].to_s) || BCrypt::Password.create("dummy")

      return render json: { error: "Credenciais inválidas" }, status: :unauthorized unless valid && user

      render json: {
        token: Auth::TokenEncoder.new.call(user),
        user: Auth::UserSerializer.new(user).call
      }
    end

    def register
      user = User.new(register_params)

      if user.save
        render json: {
          token: Auth::TokenEncoder.new.call(user),
          user: Auth::UserSerializer.new(user).call
        }, status: :created
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def logout
      token = request.headers["Authorization"].split(" ").last
      jti = JWT.decode(token, ENV.fetch("JWT_SECRET"), true, algorithm: "HS256").first["jti"]

      # TTL = o que resta da expiração. Depois disso o token morre sozinho e a
      # entrada vira lixo no Redis.
      ttl = [ token_ttl(jti), 0 ].max
      Rails.cache.write("jwt:revoked:#{jti}", true, expires_in: ttl) if ttl.positive?

      head :no_content
    end

    private

    def register_params
      params.require(:user).permit(:email, :name, :password, :password_confirmation)
    end

    def token_ttl(jti)
      payload, = JWT.decode(jti, "", false)
      payload["exp"].to_i - Time.now.to_i
    end
  end
end
```

### Login Timing

O bcrypt roda mesmo sem usuário encontrado. Sem isso, um login de e-mail
inexistente responde em 2 ms e um de e-mail existente responde em 100 ms — o
diferença revela quais e-mails têm conta.

### Logout e Blacklist

O token precisa de `jti` para ser revogável individual. Uma blacklist por
usuário não funciona bem: logout em um device desloga todos.

A entrada na blacklist expira junto com o token, para não crescer sem limite.

## Senhas

```ruby
class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 12 }, if: -> { password.present? }
end
```

Mínimo de **12 caracteres**. Comprimento supera complexidade: `Xk7#mQ2!vR$9` é
mais forte e mais usável que `Senha@123!` com 9 caracteres.

## Rate Limiting

```ruby
# config/initializers/rack_attack.rb
Rack::Attack.throttle("login attempts", limit: 5, period: 30.seconds) do |req|
  req.ip if req.path == "/api/v1/auth/login" && req.post?
end

Rack::Attack.throttle("registration attempts", limit: 3, period: 1.hour) do |req|
  req.ip if req.path == "/api/v1/auth/register" && req.post?
end
```

Cinco tentativas a cada 30 segundos permite login legítimo de usuário com senha
errada, e bloqueia brute force.

## Onde o Token Fica

| Contexto | Armazenamento |
|----------|---------------|
| SPA / SPA mobile | memória, **nunca** `localStorage` |
| SSR com sessão | cookie `HttpOnly` + `Secure` + `SameSite=Lax` |

`localStorage` é legível por qualquer XSS. `HttpOnly` não.

## Checklist

- [ ] `JWT_SECRET` com 32 bytes ou mais, em variável de ambiente
- [ ] `algorithm:` explícito no decode
- [ ] bcrypt executado mesmo sem usuário, para não vazar por timing
- [ ] blacklist por `jti`, com TTL igual ao do token
- [ ] autorização por recurso, não só por token
- [ ] rate limit em login e cadastro
- [ ] senha mínima de 12 caracteres
- [ ] token nunca em `localStorage`
- [ ] `sub`, `exp`, `iat` no payload