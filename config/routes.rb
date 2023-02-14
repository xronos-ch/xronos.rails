Rails.application.routes.draw do
  use_doorkeeper

  # Static pages
  root to: "pages#home"
  get '/home' => 'pages#home'
  get '/database' => 'pages#database'
  get '/api' => 'pages#api'

  # Articles (news posts and pseudo-static pages)
  resources :articles
  get '/news', to: 'articles#feed', section: 'news'
  get 'news/:slug', to: 'articles#show'
  get 'about/:slug', to: 'articles#show'
  get 'docs/:slug', to: 'articles#show'

  # Redirects for backwards compatibility
  get '/about', to: redirect('/about/xronos')

  # Ordinary resources
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
  resources :samples
  resources :sites do
    get 'search', on: :collection
  end
  resources :site_types do
    get 'search', on: :collection
  end
  resources :taxons do
    get 'search', on: :collection
  end
  resources :typos

  # User management
  resources :user_profiles
  devise_for :users, controllers: {
      registrations: 'registrations',
      sessions: 'users/sessions'
    }

  # Data views
  get 'data/index'
  post 'data/index'
  get "/data" => "data#index"

  # Search
  get "search" => "searches#index"

  # Data filter controls
  get '/resetfilter', :to=>'data#reset_filter_session_variable'
  get '/turn_off_lasso', :to=>'data#turn_off_lasso'
  get '/reset_manual_table_selection', :to=>'data#reset_manual_table_selection'

  # Curate
  get "/curate" => "curate#index"
  namespace :curate do
    resources :import_tables do
      get 'edit' => 'import_tables#edit_read_options'
      get 'edit/read_options' => 'import_tables#edit_read_options'
      get 'edit/mapping' => 'import_tables#edit_mapping'
    end
  end

  # API
  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do
      resources :data
    end
  end
  
end
