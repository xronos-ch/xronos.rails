Rails.application.routes.draw do
  use_doorkeeper

  # Static pages
  root to: "pages#home"
  get '/home' => 'pages#home'
  get '/database' => 'pages#database'
  get '/api' => 'pages#api'

  # Static about pages
  get '/about', to: 'about#show', defaults: { page: 'about' }
  get '/about/about', to: redirect('/about')
  get '/about/:page' => 'about#show'

  # Ordinary resources
  resources :c14s do
    member do
      get 'calibrate'
      get 'calibrate_multi'
      get 'calibrate_sum'
    end
  end
  resources :c14_labs
  resources :contexts
  resources :materials
  resources :measurement_states
  resources :references
  resources :samples
  resources :sites
  resources :site_types
  resources :source_databases
  resources :taxons
  resources :typos

  # User management
  resources :user_profiles
  devise_for :users, controllers: {
      registrations: "registrations"
    }

  # Data views
  get 'data/index'
  post 'data/index'
  get "/table" => "data#index"
  get "/map" => "data#map"
  get "/curate" => "curate#dashboard"

  # Data filter controls
  get '/resetfilter', :to=>'data#reset_filter_session_variable'
  get '/turn_off_lasso', :to=>'data#turn_off_lasso'
  get '/reset_manual_table_selection', :to=>'data#reset_manual_table_selection'
  post 'data/activate_right_window'
  post 'data/deactivate_right_window'
  post 'data/activate_left_window'
  post 'data/deactivate_left_window'
  post 'data/extend_left_window'
  post 'data/reduce_left_window'

  # Data autocomplete
  get 'data/autocomplete_source_database_name'
  get 'data/autocomplete_ecochronological_unit_name'
  get 'data/autocomplete_typochronological_unit_name'
  get 'data/autocomplete_period_name'
  get 'data/autocomplete_reference_short_ref'
  get 'data/autocomplete_material_name'
  get 'data/autocomplete_feature_type_name'
  get 'data/autocomplete_site_type_name'
  get 'data/autocomplete_country_name'
  get 'data/autocomplete_site_name'

  # API
  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do
      resources :data
    end
  end
  
end
