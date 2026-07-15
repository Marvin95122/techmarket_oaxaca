class MarcasController < ApplicationController
  before_action :autenticar_usuario!, only: [:create, :update, :destroy]
  before_action :solo_administrador!, only: [:create, :update, :destroy]
  before_action :buscar_marca, only: [:show, :update, :destroy]

  def index
    marcas = Marca.order(:nombre)
    marcas = marcas.where(activa: true) unless params[:todas] == "true"

    render json: {
      mensaje: "Listado de marcas",
      total: marcas.count,
      marcas: marcas.map { |marca| formato_marca(marca) }
    }, status: :ok
  end

  def show
    render json: formato_marca(@marca), status: :ok
  end

  def create
    marca = Marca.new(marca_params)

    if marca.save
      render json: {
        mensaje: "Marca creada correctamente",
        marca: formato_marca(marca)
      }, status: :created
    else
      render json: {
        mensaje: "No se pudo crear la marca",
        errores: marca.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    if @marca.update(marca_params)
      render json: {
        mensaje: "Marca actualizada correctamente",
        marca: formato_marca(@marca)
      }, status: :ok
    else
      render json: {
        mensaje: "No se pudo actualizar la marca",
        errores: @marca.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    if @marca.destroy
      render json: {
        mensaje: "Marca eliminada correctamente",
        marca: formato_marca(@marca)
      }, status: :ok
    else
      render json: {
        mensaje: "No se puede eliminar la marca porque tiene artículos relacionados",
        errores: @marca.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def buscar_marca
    @marca = Marca.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { mensaje: "Marca no encontrada" }, status: :not_found
  end

  def marca_params
    params.permit(:nombre, :descripcion, :activa)
  end

  def formato_marca(marca)
    {
      id: marca.id,
      nombre: marca.nombre,
      descripcion: marca.descripcion,
      activa: marca.activa,
      total_articulos: marca.articulos.count
    }
  end
end
