class ArticulosController < ApplicationController
  def index
    articulos = Articulo.all.order(:id)

    render json: {
      mensaje: "Listado de artículos de TechMarket Oaxaca",
      total: articulos.count,
      articulos: articulos
    }, status: :ok
  end

  def show
    articulo = Articulo.find(params[:id])

    render json: articulo, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: {
      mensaje: "Artículo no encontrado"
    }, status: :not_found
  end

  def create
    articulo = Articulo.new(articulo_params)

    if articulo.save
      render json: {
        mensaje: "Artículo creado correctamente",
        articulo: articulo
      }, status: :created
    else
      render json: {
        mensaje: "No se pudo crear el artículo",
        errores: articulo.errors.full_messages
      }, status: :bad_request
    end
  end

  def update
    articulo = Articulo.find(params[:id])

    if articulo.update(articulo_params)
      render json: {
        mensaje: "Artículo actualizado correctamente",
        articulo: articulo
      }, status: :ok
    else
      render json: {
        mensaje: "No se pudo actualizar el artículo",
        errores: articulo.errors.full_messages
      }, status: :bad_request
    end
  rescue ActiveRecord::RecordNotFound
    render json: {
      mensaje: "Artículo no encontrado"
    }, status: :not_found
  end

  def destroy
    articulo = Articulo.find(params[:id])
    articulo.destroy

    render json: {
      mensaje: "Artículo eliminado correctamente",
      articulo: articulo
    }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: {
      mensaje: "Artículo no encontrado"
    }, status: :not_found
  end

  private

  def articulo_params
    params.permit(:nombre, :descripcion, :precio, :stock, :categoria, :imagen_url)
  end
end