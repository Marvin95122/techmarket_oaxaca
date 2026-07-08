Rails.application.routes.draw do
  root "articulos#index"

  post "/login", to: "auth#login"
  get "/perfil", to: "auth#perfil"

  resources :usuarios, only: [
    :index,
    :show,
    :create,
    :update,
    :destroy
  ]

  resources :articulos, only: [
    :index,
    :show,
    :create,
    :update,
    :destroy
  ]

  resources :resenas, only: [
    :index,
    :show,
    :create,
    :update,
    :destroy
  ]

  resource :carrito, controller: "carritos", only: [:show] do
    post "items/:articulo_id", action: :agregar
    delete "items/:id", action: :eliminar
  end

  resources :compras, only: [
    :index,
    :show,
    :create
  ]
end