Rails.application.routes.draw do
  get 'about/acknowledgements', to: 'static_pages#acknowledgements', as: :acknowledgements
  use_doorkeeper

  # Static pages
  root to: "pages#home"
  get '/home' => 'pages#home'
  get '/database' => 'pages#database'
  get '/api' => 'pages#api'

  # Articles (news posts and other pseudo-static pages)
  get '/news', to: 'articles#index', section: 'news'
  get "/news.atom", to: "articles#index", format: :atom, section: "news"
  get "/news.rss",  to: "articles#index", format: :rss, section: "news"
  get "/:section/:slug", to: "articles#show", as: :article,
    constraints: { section: /(news|about|docs)/ }

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
  resources :controlled_vocabularies, only: :index
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
    resources :site_names, except: [:index, :show]
    scope module: :sites do
      resource :description, only: :show
    end
  end
  resources :site_types do
    get 'search', on: :collection
  end
  resources :typos, except: [:show] do
    get 'search', on: :collection
  end
  resources :functional_classifications, only: [:index, :create, :update, :destroy]

  # Secondary data resources (no independent show/index views)
  resources :samples, only: [:index, :show]
  resources :taxons, except: [:show]
  resources :taxon_usages, only: [:index, :show]

  # External data resources
  # Note: the curation namespace below is defined first so that
  # /linked_resources/sites matches the sites dashboard rather than
  # the show action of the CRUD resource (where 'sites' would be
  # treated as an :id).
  namespace :linked_resources do
    resources :sites, only: :index do
      collection do
        get ":issue", action: :index,
          constraints: lambda { |req| Site.linked_resource_issues.include?(req.params[:issue].to_sym) }
      end
    end
  end

  resources :linked_resources, except: :index

  # User management
  devise_for :users, controllers: {
      registrations: 'registrations',
      sessions: 'users/sessions'
    }
  resources :user_profiles, except: [:index, :show] do
    resource :photo, only: [ :destroy ], controller: "user_profiles/photo"
  end
  resources :contributors, controller: :user_profiles, only: [ :show ]

  # Admin interface
  get "/admin" => "admin#index"
  namespace :admin do
    resources :articles, except: :show
    resources :users
  end
  mount MissionControl::Jobs::Engine, at: "/admin/jobs"

  # Data browser
  get 'data/index'
  post 'data/index'
  get "/data" => "xronos_data#index"

  # Search
  get "search" => "searches#index"

  # Data filter controls
  get '/resetfilter', to: 'xronos_data#reset_filter_session_variable'
  get '/turn_off_lasso', to: 'xronos_data#turn_off_lasso'
  get '/reset_manual_table_selection', to: 'xronos_data#reset_manual_table_selection'

  # Curation backend
  get "/curate" => "curate#index"
  namespace :curate do
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
    resources :contexts, only: :index do
      collection do
        get ":issue", action: :index,
            constraints: lambda { |req| Context.issues.include?(req.params[:issue].to_sym) }
      end
    end
  end
  
  # LODs

  # API
  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do
      resources :data, controller: 'xronos_data'
    end
  end
  
end
