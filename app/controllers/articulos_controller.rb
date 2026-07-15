class ArticulosController < ApplicationController
  before_action :autenticar_usuario!, only: [:create, :update, :destroy]
  before_action :solo_administrador!, only: [:create, :update, :destroy]

  def index
    articulos = Articulo.includes(:categoria, :marca, :promociones).order(:id)
    articulos = articulos.where(categoria_id: params[:categoria_id]) if params[:categoria_id].present?
    articulos = articulos.where(marca_id: params[:marca_id]) if params[:marca_id].present?

    if params[:buscar].present?
      termino = "%#{ActiveRecord::Base.sanitize_sql_like(params[:buscar])}%"
      articulos = articulos.where(
        "articulos.nombre ILIKE :termino OR articulos.descripcion ILIKE :termino",
        termino: termino
      )
    end

    articulos = articulos.where("stock > 0") if params[:con_stock] == "true"

    render json: {
      mensaje: "Listado de artículos de TechMarket Oaxaca",
      total: articulos.count,
      articulos: articulos.map { |articulo| formato_articulo(articulo) }
    }, status: :ok
  end

  def show
    articulo = Articulo.includes(:categoria, :marca, :promociones).find(params[:id])

    render json: formato_articulo(articulo), status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { mensaje: "Artículo no encontrado" }, status: :not_found
  end

  def create
    articulo = Articulo.new(articulo_params)

    if articulo.save
      render json: {
        mensaje: "Artículo creado correctamente",
        articulo: formato_articulo(articulo)
      }, status: :created
    else
      render json: {
        mensaje: "No se pudo crear el artículo",
        errores: articulo.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    articulo = Articulo.find(params[:id])

    if articulo.update(articulo_params)
      render json: {
        mensaje: "Artículo actualizado correctamente",
        articulo: formato_articulo(articulo)
      }, status: :ok
    else
      render json: {
        mensaje: "No se pudo actualizar el artículo",
        errores: articulo.errors.full_messages
      }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { mensaje: "Artículo no encontrado" }, status: :not_found
  end

  def destroy
    articulo = Articulo.find(params[:id])

    if articulo.destroy
      render json: {
        mensaje: "Artículo eliminado correctamente",
        articulo: formato_articulo(articulo)
      }, status: :ok
    else
      render json: {
        mensaje: "No se puede eliminar el artículo porque está relacionado con una compra",
        errores: articulo.errors.full_messages
      }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { mensaje: "Artículo no encontrado" }, status: :not_found
  end

  private

  def articulo_params
    params.permit(
      :nombre,
      :descripcion,
      :precio,
      :stock,
      :categoria_id,
      :marca_id,
      :imagen_url
    )
  end

  def formato_articulo(articulo)
    promocion = articulo.mejor_promocion_vigente

    {
      id: articulo.id,
      nombre: articulo.nombre,
      descripcion: articulo.descripcion,
      precio: articulo.precio,
      precio_final: articulo.precio_final,
      stock: articulo.stock,
      imagen_url: articulo.imagen_url,
      categoria: {
        id: articulo.categoria.id,
        nombre: articulo.categoria.nombre
      },
      marca: {
        id: articulo.marca.id,
        nombre: articulo.marca.nombre
      },
      promocion: promocion && {
        id: promocion.id,
        nombre: promocion.nombre,
        tipo_descuento: promocion.tipo_descuento,
        valor: promocion.valor
      }
    }
  end
end
