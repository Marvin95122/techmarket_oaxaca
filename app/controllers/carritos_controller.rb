class CarritosController < ApplicationController
  before_action :autenticar_usuario!
  before_action :usuario_o_administrador!

  def show
    items = usuario_actual
            .carrito_items
            .includes(articulo: :promociones)
            .order(:id)

    render json: {
      mensaje: "Carrito del usuario",
      total: calcular_total(items),
      items: items.map { |item| formato_item(item) }
    }, status: :ok
  end

  def agregar
    articulo = Articulo.find(params[:articulo_id])
    cantidad = params[:cantidad].present? ? params[:cantidad].to_i : 1

    if cantidad <= 0
      return render json: {
        mensaje: "La cantidad debe ser mayor a 0"
      }, status: :bad_request
    end

    item = CarritoItem.find_or_initialize_by(
      usuario: usuario_actual,
      articulo: articulo
    )

    # Cuando el artículo todavía no existe en el carrito, Active Record
    # aplica el valor predeterminado de la columna cantidad (1). Por eso no
    # debemos sumarlo: la cantidad inicial debe ser exactamente la solicitada.
    nueva_cantidad =
      if item.persisted?
        item.cantidad.to_i + cantidad
      else
        cantidad
      end

    if nueva_cantidad > articulo.stock
      return render json: {
        mensaje: "No hay suficiente stock disponible"
      }, status: :bad_request
    end

    item.cantidad = nueva_cantidad
    item.save!

    render json: {
      mensaje: "Artículo agregado al carrito",
      item: formato_item(item),
      total: calcular_total(
        usuario_actual.carrito_items.includes(articulo: :promociones)
      )
    }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: {
      mensaje: "Artículo no encontrado"
    }, status: :not_found
  end

  def actualizar
    item = usuario_actual
           .carrito_items
           .includes(articulo: :promociones)
           .find(params[:id])

    cantidad = params[:cantidad].to_i

    if cantidad <= 0
      return render json: {
        mensaje: "La cantidad debe ser mayor a 0"
      }, status: :bad_request
    end

    if cantidad > item.articulo.stock
      return render json: {
        mensaje: "No hay suficiente stock disponible"
      }, status: :bad_request
    end

    item.update!(cantidad: cantidad)

    render json: {
      mensaje: "Cantidad actualizada correctamente",
      item: formato_item(item),
      total: calcular_total(
        usuario_actual.carrito_items.includes(articulo: :promociones)
      )
    }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: {
      mensaje: "Artículo del carrito no encontrado"
    }, status: :not_found
  end

  def eliminar
    item = usuario_actual
           .carrito_items
           .includes(articulo: :promociones)
           .find(params[:id])

    item.destroy!

    render json: {
      mensaje: "Artículo eliminado del carrito",
      item: formato_item(item),
      total: calcular_total(
        usuario_actual.carrito_items.includes(articulo: :promociones)
      )
    }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: {
      mensaje: "Artículo del carrito no encontrado"
    }, status: :not_found
  end

  private

  def calcular_total(items)
    items.sum do |item|
      item.cantidad * item.articulo.precio_final
    end
  end

  def formato_item(item)
    precio_unitario = item.articulo.precio_final
    promocion = item.articulo.mejor_promocion_vigente

    {
      id: item.id,
      cantidad: item.cantidad,
      subtotal: item.cantidad * precio_unitario,
      articulo: {
        id: item.articulo.id,
        nombre: item.articulo.nombre,
        precio_original: item.articulo.precio,
        precio_unitario: precio_unitario,
        stock: item.articulo.stock,
        promocion: promocion && {
          id: promocion.id,
          nombre: promocion.nombre
        }
      }
    }
  end
end
