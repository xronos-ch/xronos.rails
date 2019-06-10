Rails.application.routes.draw do
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
  get 'welcome/index'
  root 'welcome#index'
end
