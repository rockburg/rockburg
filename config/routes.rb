require "sidekiq/web"

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"

  # Artist Generator
  get "artist_generator/new", as: :new_artist_generator
  post "artist_generator/create", as: :create_artist_generator
  post "artist_generator/batch", to: "artist_generator#batch", as: :batch_artist_generator

  # Static pages
  root "pages#home"
  get "about" => "pages#about"
  get "privacy" => "pages#privacy"
  get "terms" => "pages#terms"

  # Authentication
  resource :session
  resource :registration

  # Admin routes
  namespace :admin do
    root to: "dashboard#index"
    resources :artists
    resources :seasons do
      member do
        post :generate_artists
      end
    end
  end

  # Artists
  resources :artists do
    member do
      post :perform_activity
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
