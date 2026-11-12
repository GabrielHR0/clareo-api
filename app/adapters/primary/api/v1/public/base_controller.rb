module Api
  module V1
    module Public
      # Perfil, feed, campanha e prestação publicados são acessíveis sem login.
      # O que autoriza a leitura é o estado do recurso, não um token.
      class BaseController < Api::V1::BaseController
        skip_before_action :authenticate_user!
      end
    end
  end
end
