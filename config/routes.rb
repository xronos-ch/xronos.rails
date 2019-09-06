Rails.application.routes.draw do

  resources :source_databases
  get 'data/autocomplete_source_database_name'
  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do
      resources :data
    end
  end
  resources :fell_phases
  resources :species
  resources :site_phases
  resources :ecochronological_units
  get 'data/autocomplete_ecochronological_unit_name'
  resources :typochronological_units
  get 'data/autocomplete_typochronological_unit_name'
  resources :periods
  get 'data/autocomplete_period_name'
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
  get 'data/autocomplete_reference_short_ref'
  resources :materials
  get 'data/autocomplete_material_name'
  resources :feature_types
  get 'data/autocomplete_feature_type_name'
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
