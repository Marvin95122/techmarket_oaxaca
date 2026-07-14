class PromocionesController < ApplicationController
  before_action :autenticar_usuario!, only: [:admin_index, :create, :update, :destroy]
  before_action :solo_administrador!, only: [:admin_index, :create, :update, :destroy]
  before_action :buscar_promocion, only: [:show, :update, :destroy]

  def index
    promociones = Promocion.includes(:articulos).vigentes.order(:fecha_fin)

    render json: {
      mensaje: "Promociones vigentes",
      total: promociones.count,
      promociones: promociones.map { |promocion| formato_promocion(promocion) }
    }, status: :ok
  end

  def admin_index
    promociones = Promocion.includes(:articulos).order(created_at: :desc)

    render json: {
      mensaje: "Todas las promociones",
      total: promociones.count,
      promociones: promociones.map { |promocion| formato_promocion(promocion) }
    }, status: :ok
  end

  def show
    render json: formato_promocion(@promocion), status: :ok
  end

  def create
    promocion = Promocion.new(promocion_params)

    Promocion.transaction do
      promocion.save!
      asignar_articulos!(promocion)
    end

    render json: {
      mensaje: "Promoción creada correctamente",
      promocion: formato_promocion(promocion.reload)
    }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      mensaje: "No se pudo crear la promoción",
      errores: e.record.errors.full_messages
    }, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound => e
    render json: {
      mensaje: "Uno o más artículos no existen",
      error: e.message
    }, status: :not_found
  end

  def update
    Promocion.transaction do
      @promocion.update!(promocion_params)
      asignar_articulos!(@promocion) if params.key?(:articulo_ids)
    end

    render json: {
      mensaje: "Promoción actualizada correctamente",
      promocion: formato_promocion(@promocion.reload)
    }, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      mensaje: "No se pudo actualizar la promoción",
      errores: e.record.errors.full_messages
    }, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound => e
    render json: {
      mensaje: "Uno o más artículos no existen",
      error: e.message
    }, status: :not_found
  end

  def destroy
    @promocion.destroy!

    render json: {
      mensaje: "Promoción eliminada correctamente"
    }, status: :ok
  end

  private

  def buscar_promocion
    @promocion = Promocion.includes(:articulos).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { mensaje: "Promoción no encontrada" }, status: :not_found
  end

  def promocion_params
    params.permit(
      :nombre,
      :descripcion,
      :tipo_descuento,
      :valor,
      :fecha_inicio,
      :fecha_fin,
      :activa,
      :codigo
    )
  end

  def asignar_articulos!(promocion)
    ids = Array(params[:articulo_ids]).map(&:to_i).uniq
    articulos = Articulo.where(id: ids)

    if articulos.count != ids.count
      faltantes = ids - articulos.pluck(:id)
      raise ActiveRecord::RecordNotFound, "IDs no encontrados: #{faltantes.join(', ')}"
    end

    promocion.articulos = articulos
  end

  def formato_promocion(promocion)
    {
      id: promocion.id,
      nombre: promocion.nombre,
      descripcion: promocion.descripcion,
      tipo_descuento: promocion.tipo_descuento,
      valor: promocion.valor,
      fecha_inicio: promocion.fecha_inicio,
      fecha_fin: promocion.fecha_fin,
      activa: promocion.activa,
      vigente: promocion.vigente?,
      codigo: promocion.codigo,
      articulos: promocion.articulos.map do |articulo|
        {
          id: articulo.id,
          nombre: articulo.nombre,
          precio_original: articulo.precio,
          precio_promocion: promocion.precio_final(articulo.precio)
        }
      end
    }
  end
end
