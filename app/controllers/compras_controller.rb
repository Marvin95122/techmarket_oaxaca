class ComprasController < ApplicationController
  before_action :autenticar_usuario!
  before_action :usuario_o_administrador!

  def index
    compras = if usuario_actual.administrador?
                Compra.includes(:compra_items).order(:id)
              else
                usuario_actual.compras.includes(:compra_items).order(:id)
              end

    render json: {
      mensaje: "Listado de compras",
      total: compras.count,
      compras: compras.map { |compra| formato_compra(compra) }
    }, status: :ok
  end

  def show
    compra = Compra.find(params[:id])

    unless usuario_actual.administrador? || compra.usuario_id == usuario_actual.id
      return render json: {
        mensaje: "Solo puedes ver tus propias compras."
      }, status: :forbidden
    end

    render json: formato_compra(compra), status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: {
      mensaje: "Compra no encontrada"
    }, status: :not_found
  end

  def create
    items = usuario_actual.carrito_items.includes(:articulo)

    if items.empty?
      return render json: {
        mensaje: "El carrito está vacío"
      }, status: :bad_request
    end

    compra = nil

    Compra.transaction do
      total = items.sum { |item| item.cantidad * item.articulo.precio }

      items.each do |item|
        if item.cantidad > item.articulo.stock
          raise StandardError, "Stock insuficiente para #{item.articulo.nombre}"
        end
      end

      compra = Compra.create!(
        usuario: usuario_actual,
        total: total,
        estado: "pagada"
      )

      items.each do |item|
        articulo = item.articulo
        subtotal = item.cantidad * articulo.precio

        compra.compra_items.create!(
          articulo: articulo,
          cantidad: item.cantidad,
          precio_unitario: articulo.precio,
          subtotal: subtotal
        )

        articulo.update!(stock: articulo.stock - item.cantidad)
      end

      items.destroy_all
    end

    render json: {
      mensaje: "Compra realizada correctamente",
      compra: formato_compra(compra)
    }, status: :created
  rescue StandardError => e
    render json: {
      mensaje: "No se pudo realizar la compra",
      error: e.message
    }, status: :bad_request
  end

  private

  def formato_compra(compra)
    {
      id: compra.id,
      usuario_id: compra.usuario_id,
      total: compra.total,
      estado: compra.estado,
      fecha: compra.created_at,
      items: compra.compra_items.map do |item|
        {
          id: item.id,
          articulo_id: item.articulo_id,
          nombre: item.articulo.nombre,
          cantidad: item.cantidad,
          precio_unitario: item.precio_unitario,
          subtotal: item.subtotal
        }
      end
    }
  end
end