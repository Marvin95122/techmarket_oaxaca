class ArticulosController < ApplicationController
  @@articulos = [
    {
      id: 1,
      nombre: "Laptop Lenovo IdeaPad",
      descripcion: "Laptop para estudiantes, programación y tareas escolares.",
      precio: 12500.0,
      stock: 8,
      categoria: "Laptops"
    },
    {
      id: 2,
      nombre: "Mouse Logitech Inalámbrico",
      descripcion: "Mouse compacto para oficina, escuela y uso diario.",
      precio: 350.0,
      stock: 25,
      categoria: "Accesorios"
    },
    {
      id: 3,
      nombre: "Audífonos Gamer",
      descripcion: "Audífonos con micrófono para videojuegos y videollamadas.",
      precio: 780.0,
      stock: 12,
      categoria: "Audio"
    }
  ]

  @@siguiente_id = 4

  def index
    render json: {
      mensaje: "Listado de artículos de TechMarket Oaxaca",
      total: @@articulos.length,
      articulos: @@articulos
    }, status: :ok
  end

  def show
    articulo = buscar_articulo(params[:id])

    if articulo
      render json: articulo, status: :ok
    else
      render json: {
        mensaje: "Artículo no encontrado"
      }, status: :not_found
    end
  end

  def create
    datos = articulo_params.to_h.symbolize_keys

    if datos[:nombre].blank? || datos[:descripcion].blank? || datos[:precio].blank? || datos[:stock].blank? || datos[:categoria].blank?
      return render json: {
        mensaje: "Faltan datos obligatorios: nombre, descripcion, precio, stock y categoria"
      }, status: :bad_request
    end

    nuevo_articulo = {
      id: @@siguiente_id,
      nombre: datos[:nombre],
      descripcion: datos[:descripcion],
      precio: datos[:precio].to_f,
      stock: datos[:stock].to_i,
      categoria: datos[:categoria]
    }

    @@articulos << nuevo_articulo
    @@siguiente_id += 1

    render json: {
      mensaje: "Artículo creado correctamente",
      articulo: nuevo_articulo
    }, status: :created
  end

  def update
    articulo = buscar_articulo(params[:id])

    unless articulo
      return render json: {
        mensaje: "Artículo no encontrado"
      }, status: :not_found
    end

    datos = articulo_params.to_h.symbolize_keys

    articulo[:nombre] = datos[:nombre] if datos.key?(:nombre)
    articulo[:descripcion] = datos[:descripcion] if datos.key?(:descripcion)
    articulo[:precio] = datos[:precio].to_f if datos.key?(:precio)
    articulo[:stock] = datos[:stock].to_i if datos.key?(:stock)
    articulo[:categoria] = datos[:categoria] if datos.key?(:categoria)

    render json: {
      mensaje: "Artículo actualizado correctamente",
      articulo: articulo
    }, status: :ok
  end

  def destroy
    articulo = buscar_articulo(params[:id])

    unless articulo
      return render json: {
        mensaje: "Artículo no encontrado"
      }, status: :not_found
    end

    @@articulos.delete(articulo)

    render json: {
      mensaje: "Artículo eliminado correctamente",
      articulo: articulo
    }, status: :ok
  end

  private

  def buscar_articulo(id)
    @@articulos.find { |articulo| articulo[:id] == id.to_i }
  end

  def articulo_params
    params.permit(:nombre, :descripcion, :precio, :stock, :categoria)
  end
end