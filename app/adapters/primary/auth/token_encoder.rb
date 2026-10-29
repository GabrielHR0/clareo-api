module Auth
  # HS256 com expiração curta. O jti é o que permite revogar um token no logout
  # sem derrubar os outros dispositivos do mesmo usuário.
  class TokenEncoder
    ALGORITHM = "HS256"

    def initialize(secret: ENV.fetch("JWT_SECRET"),
                   expiration: Integer(ENV.fetch("JWT_EXPIRATION", 86_400)))
      @secret = secret
      @expiration = expiration
    end

    def call(user)
      now = Time.now.to_i
      payload = {
        sub: user.id.to_s,
        email: user.email,
        role: user.role,
        jti: SecureRandom.uuid,
        iat: now,
        exp: now + @expiration
      }

      JWT.encode(payload, @secret, ALGORITHM)
    end
  end
end
