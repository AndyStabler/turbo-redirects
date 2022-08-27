Rails.application.routes.draw do
  resources :users
  root "main#index"
end
