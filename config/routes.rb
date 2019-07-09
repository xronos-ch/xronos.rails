Rails.application.routes.draw do
  devise_for :users
  resources :dendro_measurements
  resources :c14_measurements
  resources :measurements
  resources :samples
  resources :arch_objects
  resources :labs
  resources :cultures
  resources :phases
  resources :references
  resources :species
  resources :materials
  resources :feature_types
  resources :on_site_object_positions
  resources :site_types
  resources :countries
  resources :sites
  get 'data/index'
  root 'data#index'
  root to: "data#index"
  get '/api' => 'pages#api'
  get '/about' => 'pages#about'
end
