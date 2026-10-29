Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "auth/login", to: "auth#login"
      post "auth/register", to: "auth#register"
      post "auth/logout", to: "auth#logout"

      resources :institutions, only: [] do
        resources :accountability_reports,
          only: %i[index show create update],
          controller: "institutions/accountability_reports" do
          member do
            post :submit
            post :publish
          end
        end
      end

      namespace :admin do
        resources :accountability_reports, only: %i[index show] do
          member do
            post :start_review
            post :approve
            post :request_changes
          end
        end
      end

      namespace :public do
        get "campaigns", to: "campaigns#index"
        get "institutions/:slug", to: "institutions#show"
        get "institutions/:slug/feed", to: "institutions#feed"
        get "institutions/:slug/campaigns/:id", to: "campaigns#show"
        get "institutions/:slug/accountability_reports",
          to: "accountability_reports#index"
        get "accountability_reports/:id", to: "accountability_reports#show"
      end
    end
  end
end
