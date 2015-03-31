Rails.application.routes.draw do
  root 'languages#index'

  resources :languages, except: [:index]
end
