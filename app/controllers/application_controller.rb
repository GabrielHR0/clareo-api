class ApplicationController < ActionController::API
  before_action :authenticate_user!

  attr_reader :current_user

  private

  def authenticate_user!
    token = bearer_token
    return unauthorized("Token não fornecido") if token.nil?

    @auth_payload = Auth::TokenDecoder.new.call(token)
    return unauthorized("Token revogado") if revoked?(@auth_payload["jti"])

    @current_user = UserRecord.find_by(id: @auth_payload["sub"])
    unauthorized("Usuário não encontrado") if @current_user.nil?
  rescue Auth::ExpiredError
    unauthorized("Token expirado")
  rescue Auth::InvalidError
    unauthorized("Token inválido")
  end

  def authorize_institution!(institution)
    return true if current_user.platform_admin?
    return true if current_user.owns?(institution)

    forbidden
    false
  end

  def require_platform_admin!
    return if current_user&.platform_admin?

    forbidden
  end

  def revoke_current_token!
    jti = @auth_payload&.fetch("jti", nil)
    return if jti.nil?

    ttl = @auth_payload["exp"].to_i - Time.now.to_i
    return unless ttl.positive?

    Rails.cache.write("jwt:revoked:#{jti}", true, expires_in: ttl)
  end

  def bearer_token
    scheme, token = request.headers["Authorization"].to_s.split(" ", 2)
    return nil unless scheme&.casecmp("Bearer")&.zero?

    token
  end

  def revoked?(jti)
    return false if jti.nil?

    Rails.cache.exist?("jwt:revoked:#{jti}")
  end

  def unauthorized(message)
    render json: { error: message, code: "unauthorized" }, status: :unauthorized
  end

  def forbidden(message = "Não autorizado")
    render json: { error: message, code: "forbidden" }, status: :forbidden
  end
end
