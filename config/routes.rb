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

  # Primary data resources
  resources :c14s do
    get 'search', on: :collection
    member do
      get 'calibrate'
      get 'calibrate_multi'
      get 'calibrate_sum'
    end
  end
  resources :c14_labs
  resources :contexts
  resources :duplicates
  resources :materials do
    get 'search', on: :collection
  end
  resources :measurement_states
  resources :references
  resources :sites do
    get 'search', on: :collection
  end
  resources :site_types do
    get 'search', on: :collection
  end
  resources :typos

  # Secondary data resources (no independent show/index views)
  resources :taxons, except: [:index, :show] do
    get 'search', on: :collection
  end

  # User management
  resources :user_profiles
  devise_for :users, controllers: {
      registrations: "registrations"
    }

  # Data browser
  get 'data/index'
  post 'data/index'
  get "/data" => "data#index"

  # Search
  get "search" => "searches#index"

  # Data filter controls
  get '/resetfilter', :to=>'data#reset_filter_session_variable'
  get '/turn_off_lasso', :to=>'data#turn_off_lasso'
  get '/reset_manual_table_selection', :to=>'data#reset_manual_table_selection'

  # Curation backend
  get "/curate" => "curate#index"
  namespace :curate do
    resources :import_tables do
      get 'edit' => 'import_tables#edit_read_options'
      get 'edit/read_options' => 'import_tables#edit_read_options'
      get 'edit/mapping' => 'import_tables#edit_mapping'
    end
  end

  # Data issues
  concern :has_issues do
    collection do
      get ":issue", action: :index
    end
  end
  namespace :issues do 
    resources :samples, only: :index, concerns: :has_issues
    resources :taxons, only: :index, concerns: :has_issues
  end

  # API
  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do
      resources :data
    end
  end
  
end
