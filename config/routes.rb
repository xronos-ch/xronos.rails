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
  get 'data/autocomplete_site_type_name'
  resources :countries
  get 'data/autocomplete_country_name'
  resources :sites
  get 'data/index'
  root 'data#index'
  root to: "data#index"
  get '/api' => 'pages#api'
  get '/about' => 'pages#about'
  get '/resetfilter', :to=>'data#reset_filter_session_variable'
end
