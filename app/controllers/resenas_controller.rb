class ResenasController < ApplicationController
  before_action :autenticar_usuario!, only: [:create, :update, :destroy]
  before_action :usuario_o_administrador!, only: [:create, :update, :destroy]

  def index
    resenas = Resena.includes(:usuario, :articulo).order(created_at: :desc)

    if params[:articulo_id].present?
      resenas = resenas.where(articulo_id: params[:articulo_id])
    end

    render json: {
      mensaje: "Listado de reseñas",
      total: resenas.count,
      resenas: resenas.map { |resena| formato_resena(resena) }
    }, status: :ok
  end

  def show
    resena = Resena.includes(:usuario, :articulo).find(params[:id])

    render json: formato_resena(resena), status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: {
      mensaje: "Reseña no encontrada"
    }, status: :not_found
  end

  def create
    articulo_id = params[:articulo_id]

    if articulo_id.blank?
      return render json: {
        mensaje: "Debes indicar el producto que deseas reseñar."
      }, status: :unprocessable_entity
    end

    articulo = Articulo.find_by(id: articulo_id)

    unless articulo
      return render json: {
        mensaje: "El producto indicado no existe."
      }, status: :not_found
    end

    unless producto_comprado_por_usuario?(articulo.id)
      return render json: {
        mensaje: "Solo puedes reseñar productos que hayas comprado en una compra pagada."
      }, status: :forbidden
    end

    resena = usuario_actual.resenas.new(
      articulo: articulo,
      calificacion: params[:calificacion],
      comentario: params[:comentario]
    )

    if resena.save
      render json: {
        mensaje: "Reseña creada correctamente",
        resena: formato_resena(resena)
      }, status: :created
    else
      render json: {
        mensaje: "No se pudo crear la reseña",
        errores: resena.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    resena = Resena.includes(:usuario, :articulo).find(params[:id])

    unless usuario_actual.administrador? || resena.usuario_id == usuario_actual.id
      return render json: {
        mensaje: "Solo puedes modificar tus propias reseñas."
      }, status: :forbidden
    end

    # El artículo no puede cambiarse al editar una reseña.
    # De esta manera no es posible convertir una reseña válida en una reseña
    # para otro producto que el usuario nunca compró.
    if resena.update(update_resena_params)
      render json: {
        mensaje: "Reseña actualizada correctamente",
        resena: formato_resena(resena)
      }, status: :ok
    else
      render json: {
        mensaje: "No se pudo actualizar la reseña",
        errores: resena.errors.full_messages
      }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: {
      mensaje: "Reseña no encontrada"
    }, status: :not_found
  end

  def destroy
    resena = Resena.includes(:usuario, :articulo).find(params[:id])

    unless usuario_actual.administrador? || resena.usuario_id == usuario_actual.id
      return render json: {
        mensaje: "Solo puedes eliminar tus propias reseñas."
      }, status: :forbidden
    end

    resena.destroy!

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

  def update_resena_params
    params.permit(:calificacion, :comentario)
  end

  def producto_comprado_por_usuario?(articulo_id)
    usuario_actual
      .compras
      .where(estado: "pagada")
      .joins(:compra_items)
      .where(compra_items: { articulo_id: articulo_id })
      .exists?
  end

  def formato_resena(resena)
    {
      id: resena.id,
      calificacion: resena.calificacion,
      comentario: resena.comentario,
      created_at: resena.created_at,
      updated_at: resena.updated_at,
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
