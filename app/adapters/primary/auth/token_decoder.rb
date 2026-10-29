module Auth
  # O algorithm explícito não é detalhe: sem ele o JWT respeita o alg do próprio
  # token, e alg: none passa.
  class TokenDecoder
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
end
