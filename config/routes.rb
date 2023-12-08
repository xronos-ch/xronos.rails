Rails.application.routes.draw do
  use_doorkeeper

  # Static pages
  root to: "pages#home"
  get '/home' => 'pages#home'
  get '/database' => 'pages#database'
  get '/api' => 'pages#api'

  # Articles (news posts and other pseudo-static pages)
  get '/news', to: 'articles#index', section: 'news'
  get 'news/:slug', to: 'articles#show'
  get 'about/:slug', to: 'articles#show'
  get 'docs/:slug', to: 'articles#show'
  namespace :admin do
    resources :articles, except: :show
  end

  # Redirects for backwards compatibility
  get '/about', to: redirect('/about/xronos')

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
  resources :references do
    get 'search', on: :collection
  end
  resources :sites do
    get 'search', on: :collection
  end
  resources :site_types do
    get 'search', on: :collection
  end
  resources :typos do
    get 'search', on: :collection
  end

  # Secondary data resources (no independent show/index views)
  resources :taxons, except: [:index, :show] do
    get 'search', on: :collection
  end
  resources :taxon_usages, only: :show

  # User management
  devise_for :users, controllers: {
      registrations: 'registrations',
      sessions: 'users/sessions'
    }
  resources :user_profiles, except: [:index, :show] do
    resource :photo, only: [ :destroy ], controller: "user_profiles/photo"
  end
  resources :contributors, controller: :user_profiles, only: [ :show ]

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
    get "recent_changes" => "recent_changes#index"
  end

  # Data issues
  namespace :issues do 
    resources :c14s, only: :index do
      collection do
        get ":issue", action: :index,
          constraints: lambda { |req| C14.issues.include?(req.params[:issue].to_sym) }
      end
    end
    resources :references, only: :index do
      collection do
        get ":issue", action: :index,
          constraints: lambda { |req| Reference.issues.include?(req.params[:issue].to_sym) }
      end
    end
    resources :samples, only: :index do
      collection do
        get ":issue", action: :index,
          constraints: lambda { |req| Sample.issues.include?(req.params[:issue].to_sym) }
      end
    end
    resources :sites, only: :index do
      collection do
        get ":issue", action: :index,
          constraints: lambda { |req| Site.issues.include?(req.params[:issue].to_sym) }
      end
    end
    resources :taxons, only: :index do
      collection do
        get ":issue", action: :index,
          constraints: lambda { |req| Taxon.issues.include?(req.params[:issue].to_sym) }
      end
    end
  end

  # API
  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do
      resources :data
    end
  end
  
end

