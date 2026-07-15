class ResenasController < ApplicationController
  before_action :autenticar_usuario!, only: [:create, :update, :destroy]
  before_action :usuario_o_administrador!, only: [:create, :update, :destroy]

  def index
    resenas = Resena.includes(:usuario, :articulo).order(:id)

    if params[:articulo_id].present?
      resenas = resenas.where(articulo_id: params[:articulo_id])
    end

    render json: {
      mensaje: "Listado de reseñas",
      total: resenas.count,
      resenas: resenas.map { |r| formato_resena(r) }
    }, status: :ok
  end

  def show
    resena = Resena.find(params[:id])

    render json: formato_resena(resena), status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: {
      mensaje: "Reseña no encontrada"
    }, status: :not_found
  end

  def create
    resena = usuario_actual.resenas.new(resena_params)

    if resena.save
      render json: {
        mensaje: "Reseña creada correctamente",
        resena: formato_resena(resena)
      }, status: :created
    else
      render json: {
        mensaje: "No se pudo crear la reseña",
        errores: resena.errors.full_messages
      }, status: :bad_request
    end
  end

  def update
    resena = Resena.find(params[:id])

    unless usuario_actual.administrador? || resena.usuario_id == usuario_actual.id
      return render json: {
        mensaje: "Solo puedes modificar tus propias reseñas."
      }, status: :forbidden
    end

    if resena.update(resena_params)
      render json: {
        mensaje: "Reseña actualizada correctamente",
        resena: formato_resena(resena)
      }, status: :ok
    else
      render json: {
        mensaje: "No se pudo actualizar la reseña",
        errores: resena.errors.full_messages
      }, status: :bad_request
    end
  rescue ActiveRecord::RecordNotFound
    render json: {
      mensaje: "Reseña no encontrada"
    }, status: :not_found
  end

  def destroy
    resena = Resena.find(params[:id])

    unless usuario_actual.administrador? || resena.usuario_id == usuario_actual.id
      return render json: {
        mensaje: "Solo puedes eliminar tus propias reseñas."
      }, status: :forbidden
    end

    resena.destroy

    render json: {
      mensaje: "Reseña eliminada correctamente",
      resena: formato_resena(resena)
    }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: {
      mensaje: "Reseña no encontrada"
    }, status: :not_found
  end

  private

  def resena_params
    params.permit(:articulo_id, :calificacion, :comentario)
  end

  def formato_resena(resena)
    {
      id: resena.id,
      calificacion: resena.calificacion,
      comentario: resena.comentario,
      usuario: {
        id: resena.usuario.id,
        nombre: resena.usuario.nombre
      },
      articulo: {
        id: resena.articulo.id,
        nombre: resena.articulo.nombre
      }
    }
  end
end