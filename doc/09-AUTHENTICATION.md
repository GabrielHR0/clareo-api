# Clareo — Autenticação JWT

> Referências:
> - https://github.com/jwt/ruby-jwt
> - https://rubyonrails.org/docs/security

## Visão Geral

Autenticação baseada em JWT (JSON Web Tokens):
- Tokens expiram em 24 horas
- Refresh tokens para renovação
- Roles: donor, beneficiary, admin

## Configuração

### Gem Ruby

```ruby
# Gemfile
gem 'jwt' # Geração e validação de JWT
gem 'bcrypt' # Hash de senhas
```

### Variáveis de Ambiente

```bash
# .env
JWT_SECRET=sua_chave_secreta_mínimo_32_bytes
JWT_EXPIRATION=86400 # 24 horas em segundos
```

## Geração de Token

```ruby
# app/services/auth_service.rb
class AuthService
  SECRET_KEY = ENV['JWT_SECRET']
  EXPIRATION = ENV['JWT_EXPIRATION'].to_i || 86400

  def self.encode(payload)
    payload[:exp] = Time.now.to_i + EXPIRATION
    payload[:iat] = Time.now.to_i

    JWT.encode(payload, SECRET_KEY, 'HS256')
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY, true, { algorithm: 'HS256' })
    HashWithIndifferentAccess.new(decoded.first)
  rescue JWT::DecodeError, JWT::ExpiredSignature => e
    nil
  end
end
```

## Login

```ruby
# app/controllers/api/v1/auth_controller.rb
class Api::V1::AuthController < ApplicationController
  skip_before_action :authenticate_user!, only: [:login, :register]

  def login
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      token = AuthService.encode(user_id: user.id, role: user.role)

      render json: {
        token: token,
        user: UserSerializer.new(user)
      }
    else
      render json: { error: 'Email ou senha inválidos' }, status: :unauthorized
    end
  end

  def register
    user = User.new(user_params)

    if user.save
      token = AuthService.encode(user_id: user.id, role: user.role)

      render json: {
        token: token,
        user: UserSerializer.new(user)
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.permit(:email, :name, :password, :password_confirmation)
  end
end
```

## Middleware de Autenticação

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  before_action :authenticate_user!

  private

  def authenticate_user!
    token = request.headers['Authorization']&.split(' ')&.last

    if token.nil?
      render json: { error: 'Token não fornecido' }, status: :unauthorized
      return
    end

    decoded = AuthService.decode(token)

    if decoded.nil?
      render json: { error: 'Token inválido ou expirado' }, status: :unauthorized
      return
    end

    @current_user = User.find_by(id: decoded[:user_id])

    if @current_user.nil?
      render json: { error: 'Usuário não encontrado' }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end

  def authorize_role!(*roles)
    unless roles.include?(current_user.role)
      render json: { error: 'Não autorizado' }, status: :forbidden
    end
  end
end
```

## Exemplo de Uso

### Headers

```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

### Controller Protegido

```ruby
class Api::V1::DonationsController < ApplicationController
  def create
    donation = DonationService.create(donation_params, current_user)
    render json: donation
  end

  def show
    donation = Donation.find(params[:id])

    # Verificar se o usuário tem acesso
    unless donation.user_id == current_user.id || current_user.admin?
      render json: { error: 'Não autorizado' }, status: :forbidden
      return
    end

    render json: donation
  end
end
```

### Admin Only

```ruby
class Api::V1::Admin::WalletsController < ApplicationController
  before_action -> { authorize_role!(:admin) }

  def index
    wallets = Wallet.all
    render json: wallets
  end
end
```

## Rate Limiting

```ruby
# config/initializers/rack_attack.rb
Rack::Attack.throttle('requests by ip', limit: 20, period: 1.minute) do |req|
  req.ip unless req.path.start_with?('/assets')
end

Rack::Attack.throttle('login attempts', limit: 5, period: 30.seconds) do |req|
  if req.path == '/api/v1/auth/login' && req.post?
    req.ip
  end
end
```

## Segurança

- **NUNCA** armazene JWT no localStorage (use HttpOnly cookies em produção)
- Tokens devem expirar (não use tokens infinitos)
- Implemente blacklist de tokens para logout
- Use HTTPS obrigatoriamente
- Rate limiting em endpoints de auth
