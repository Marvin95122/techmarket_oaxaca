Rails.application.routes.draw do
  root "articulos#index"

  post "/login", to: "auth#login"
  get "/perfil", to: "auth#perfil"

  resources :usuarios, only: [:index, :show, :create, :update, :destroy] do
    member do
      patch :deshabilitar
      patch :habilitar
    end
  end

  resources :categorias, only: [:index, :show, :create, :update, :destroy]
  resources :marcas, only: [:index, :show, :create, :update, :destroy]
  resources :articulos, only: [:index, :show, :create, :update, :destroy]
  resources :resenas, only: [:index, :show, :create, :update, :destroy]

  get "/admin/promociones", to: "promociones#admin_index"
  resources :promociones, only: [:index, :show, :create, :update, :destroy]

  resource :carrito, controller: "carritos", only: [:show] do
    post "items/:articulo_id", action: :agregar
    patch "items/:id", action: :actualizar
    delete "items/:id", action: :eliminar
  end

  resources :compras, only: [:index, :show, :create] do
    member do
      patch :cancelar
      patch :actualizar_estado_envio
      patch :simular_pago_oxxo
    end
  end

  get "/reportes/ventas", to: "reportes#ventas"
  get "/dashboard/resumen", to: "dashboard#resumen"

  get "/ia/estado", to: "ia#estado"
  post "/ia/chat", to: "ia#chat"
  post "/ia/recomendaciones", to: "ia#recomendaciones"

  resources :consultas_ia, only: [:index, :show, :destroy]
end
