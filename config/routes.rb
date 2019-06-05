Rails.application.routes.draw do
  resources :countries
  resources :sites
  get 'welcome/index'
  root 'welcome#index'
end
