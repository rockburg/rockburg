require "sidekiq/web"

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"

  # Artist Selection - new routes
  get "artist_selections", to: "artist_selections#index", as: :artist_selections
  post "artist_selections/:id/select", to: "artist_selections#select", as: :select_artist

  # Sign Artist
  post "artists/:id/sign", to: "artists#sign", as: :sign_artist

  # Static pages
  root "pages#home"
  get "about" => "pages#about"
  get "privacy" => "pages#privacy"
  get "terms" => "pages#terms"

  # Authentication
  resource :session
  resource :registration
  resource :password

  # Admin routes
  namespace :admin do
    root to: "dashboard#index"
    resources :artists
    resources :seasons do
      member do
        post :generate_artists
        post :regenerate_venues
      end
    end
    resources :venues
    post "recalculate_venue_stats", to: "dashboard#recalculate_venue_stats"
    post "regenerate_venues", to: "dashboard#regenerate_venues"
  end

  # Artists
  resources :artists, except: [ :edit, :update, :destroy ] do
    member do
      post :perform_activity
      post :cancel_activity
      post :schedule_activity
      delete :cancel_scheduled_activity
    end

    # Nested route for booking performances for a specific artist
    resources :performances, only: [ :new, :create ]
  end

  # Performances
  resources :performances, only: [ :index, :show ] do
    member do
      post :cancel
      post :complete
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
