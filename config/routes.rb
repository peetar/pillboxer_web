Rails.application.routes.draw do
  # Health check for Fly.io
  get '/health', to: proc { [200, {}, ['OK']] }
  
  # Authentication routes
  get '/login', to: 'sessions#new'
  post '/login', to: 'sessions#create'
  get '/logout', to: 'sessions#destroy'
  delete '/logout', to: 'sessions#destroy'
  
  get '/signup', to: 'users#new'
  post '/signup', to: 'users#create'
  get '/profile', to: 'users#show'
  
  # Defines the root path route ("/")
  root "home#index"
  get "home/index"
  get "home/test"
  get "simple/index"
  
  # Medication management routes
  resources :medications do
    member do
      patch :toggle_taken
    end
  end
  
  # Pillbox management routes  
  resources :pillboxes do
    collection do
      get 'wizard', to: 'pillboxes#wizard'
      post 'wizard', to: 'pillboxes#wizard_create'
    end
    member do
      get 'fill', to: 'pillboxes#fill'
      post 'fill', to: 'pillboxes#mark_filled'
    end
    resources :compartments, only: [:show, :update]
  end
  
  # Schedule routes
  resources :schedules, only: [:index, :show, :create, :update, :destroy]
  
  # API routes for mobile app
  namespace :api do
    namespace :v1 do
      resources :medications, only: [:index, :show]
      resources :schedules, only: [:index, :show]
    end
  end
end