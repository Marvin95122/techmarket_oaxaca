class CategoriasController < ApplicationController
  before_action :autenticar_usuario!, only: [:create, :update, :destroy]
  before_action :solo_administrador!, only: [:create, :update, :destroy]
  before_action :buscar_categoria, only: [:show, :update, :destroy]

  def index
    categorias = Categoria.order(:nombre)
    categorias = categorias.where(activa: true) unless params[:todas] == "true"

    render json: {
      mensaje: "Listado de categorías",
      total: categorias.count,
      categorias: categorias.map { |categoria| formato_categoria(categoria) }
    }, status: :ok
  end

  def show
    render json: formato_categoria(@categoria), status: :ok
  end

  def create
    categoria = Categoria.new(categoria_params)

    if categoria.save
      render json: {
        mensaje: "Categoría creada correctamente",
        categoria: formato_categoria(categoria)
      }, status: :created
    else
      render json: {
        mensaje: "No se pudo crear la categoría",
        errores: categoria.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    if @categoria.update(categoria_params)
      render json: {
        mensaje: "Categoría actualizada correctamente",
        categoria: formato_categoria(@categoria)
      }, status: :ok
    else
      render json: {
        mensaje: "No se pudo actualizar la categoría",
        errores: @categoria.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    if @categoria.destroy
      render json: {
        mensaje: "Categoría eliminada correctamente",
        categoria: formato_categoria(@categoria)
      }, status: :ok
    else
      render json: {
        mensaje: "No se puede eliminar la categoría porque tiene artículos relacionados",
        errores: @categoria.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def buscar_categoria
    @categoria = Categoria.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { mensaje: "Categoría no encontrada" }, status: :not_found
  end

  def categoria_params
    params.permit(:nombre, :descripcion, :activa)
  end

  def formato_categoria(categoria)
    {
      id: categoria.id,
      nombre: categoria.nombre,
      descripcion: categoria.descripcion,
      activa: categoria.activa,
      total_articulos: categoria.articulos.count
    }
  end
end
