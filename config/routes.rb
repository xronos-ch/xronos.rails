Rails.application.routes.draw do

  resources :source_databases
  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do
      resources :data
    end
  end
  resources :fell_phases
  resources :species
  resources :site_phases
  resources :ecochronological_units
  resources :typochronological_units
  resources :periods
  resources :c14_measurements do
    member do
      get 'calibrate'
      get 'calibrate_multi'
      get 'calibrate_sum'
    end
  end
  devise_for :users, controllers: {
      registrations: "registrations"
    }
  resources :measurements
  resources :samples
  resources :arch_objects
  resources :labs
  resources :references
  resources :materials
  get 'data/autocomplete_material_name'
  resources :feature_types
  resources :on_site_object_positions
  resources :site_types
  get 'data/autocomplete_site_type_name'
  resources :countries
  get 'data/autocomplete_country_name'
  resources :sites
  get 'data/autocomplete_site_name'
  get 'data/index'
	post 'data/index'
  root 'data#index'
  root to: "data#index"
  get '/api' => 'pages#api'
  get '/about' => 'pages#about'
  get '/database' => 'pages#database'
  get '/resetfilter', :to=>'data#reset_filter_session_variable'
  get '/turn_off_lasso', :to=>'data#turn_off_lasso'
  get '/reset_manual_table_selection', :to=>'data#reset_manual_table_selection'
  post 'data/activate_right_window'
  post 'data/deactivate_right_window'
  post 'data/activate_left_window'
  post 'data/deactivate_left_window'
  post 'data/extend_left_window'
  post 'data/reduce_left_window'
end
