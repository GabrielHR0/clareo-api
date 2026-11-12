module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_user!, only: %i[login register]

      def login
        user = UserRecord.where("lower(email) = ?", credentials[:email].to_s.strip.downcase).first

        # bcrypt roda mesmo sem usuário: tempo de resposta semelhante evita
        # descobrir quais e-mails têm conta.
        valid = user ? user.authenticate(credentials[:password].to_s) : dummy_password_check
        return unauthorized("Credenciais inválidas") unless valid && user

        render json: {
          token: Auth::TokenEncoder.new.call(user),
          user: Auth::UserSerializer.call(user)
        }
      end

      def register
        user = UserRecord.new(
          email: credentials[:email].to_s.strip.downcase,
          name: credentials[:name],
          password: credentials[:password],
          password_confirmation: credentials[:password_confirmation],
          role: "donor"
        )

        if user.save
          render json: {
            token: Auth::TokenEncoder.new.call(user),
            user: Auth::UserSerializer.call(user)
          }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_content
        end
      end

      def logout
        revoke_current_token!
        head :no_content
      end

      private

      def credentials
        params.permit(:email, :password, :name, :password_confirmation)
      end

      def dummy_password_check
        BCrypt::Password.create("dummy-password")
        false
      end
    end
  end
end
