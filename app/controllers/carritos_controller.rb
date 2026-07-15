class CarritosController < ApplicationController
  before_action :autenticar_usuario!
  before_action :usuario_o_administrador!

  def show
    items = usuario_actual.carrito_items.includes(articulo: :promociones).order(:id)

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

    nueva_cantidad = item.cantidad.to_i + cantidad

    if nueva_cantidad > articulo.stock
      return render json: {
        mensaje: "No hay suficiente stock disponible"
      }, status: :bad_request
    end

    item.cantidad = nueva_cantidad
    item.save!

    render json: {
      mensaje: "Artículo agregado al carrito",
      item: formato_item(item)
    }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { mensaje: "Artículo no encontrado" }, status: :not_found
  end

  def eliminar
    item = usuario_actual.carrito_items.find(params[:id])
    item.destroy!

    render json: {
      mensaje: "Artículo eliminado del carrito",
      item: formato_item(item)
    }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: {
      mensaje: "Artículo del carrito no encontrado"
    }, status: :not_found
  end

  private

  def calcular_total(items)
    items.sum { |item| item.cantidad * item.articulo.precio_final }
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
