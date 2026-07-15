class ComprasController < ApplicationController
  before_action :autenticar_usuario!
  before_action :usuario_o_administrador!
  before_action :solo_administrador!, only: [:cancelar]
  before_action :buscar_compra, only: [:show, :cancelar]

  def index
    compras = if usuario_actual.administrador?
                Compra.includes(:usuario, compra_items: :articulo).order(created_at: :desc)
              else
                usuario_actual.compras.includes(compra_items: :articulo).order(created_at: :desc)
              end

    if usuario_actual.administrador?
      compras = compras.where(estado: params[:estado]) if params[:estado].present?
      compras = compras.where(usuario_id: params[:usuario_id]) if params[:usuario_id].present?
    end

    render json: {
      mensaje: "Listado de compras",
      total: compras.count,
      compras: compras.map { |compra| formato_compra(compra) }
    }, status: :ok
  end

  def show
    unless usuario_actual.administrador? || @compra.usuario_id == usuario_actual.id
      return render json: {
        mensaje: "Solo puedes ver tus propias compras."
      }, status: :forbidden
    end

    render json: formato_compra(@compra), status: :ok
  end

  def create
    items = usuario_actual.carrito_items.includes(articulo: :promociones)

    if items.empty?
      return render json: {
        mensaje: "El carrito está vacío"
      }, status: :bad_request
    end

    compra = nil

    Compra.transaction do
      items.each do |item|
        item.articulo.lock!

        if item.cantidad > item.articulo.stock
          raise StandardError, "Stock insuficiente para #{item.articulo.nombre}"
        end
      end

      total = items.sum do |item|
        item.cantidad * item.articulo.precio_final
      end

      compra = Compra.create!(
        usuario: usuario_actual,
        total: total,
        estado: "pagada"
      )

      items.each do |item|
        articulo = item.articulo
        precio_unitario = articulo.precio_final
        subtotal = item.cantidad * precio_unitario

        compra.compra_items.create!(
          articulo: articulo,
          cantidad: item.cantidad,
          precio_unitario: precio_unitario,
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

  def cancelar
    if @compra.cancelada?
      return render json: {
        mensaje: "La compra ya se encuentra cancelada."
      }, status: :unprocessable_entity
    end

    Compra.transaction do
      @compra.lock!

      @compra.compra_items.includes(:articulo).each do |item|
        item.articulo.with_lock do
          item.articulo.update!(stock: item.articulo.stock + item.cantidad)
        end
      end

      @compra.update!(
        estado: "cancelada",
        cancelada_en: Time.current,
        motivo_cancelacion: params[:motivo].presence || "Cancelación administrativa"
      )
    end

    render json: {
      mensaje: "Compra cancelada y stock restaurado correctamente",
      compra: formato_compra(@compra.reload)
    }, status: :ok
  end

  private

  def buscar_compra
    @compra = Compra.includes(:usuario, compra_items: :articulo).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { mensaje: "Compra no encontrada" }, status: :not_found
  end

  def formato_compra(compra)
    {
      id: compra.id,
      total: compra.total,
      estado: compra.estado,
      fecha: compra.created_at,
      cancelada_en: compra.cancelada_en,
      motivo_cancelacion: compra.motivo_cancelacion,
      usuario: {
        id: compra.usuario.id,
        nombre: compra.usuario.nombre,
        correo: compra.usuario.correo
      },
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
