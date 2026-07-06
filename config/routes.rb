Rails.application.routes.draw do
  root "articulos#index"

  resources :articulos, only: [
    :index,
    :show,
    :create,
    :update,
    :destroy
  ]
end