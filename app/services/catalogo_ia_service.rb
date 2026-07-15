class CatalogoIaService
  MAX_ARTICULOS_CONTEXTO = 40
  MAX_CANDIDATOS = 8

  def catalogo_disponible(limite: MAX_ARTICULOS_CONTEXTO)
    articulos_disponibles(limite: limite).map do |articulo|
      serializar_articulo(articulo)
    end
  end

  def candidatos_recomendacion(
    presupuesto:,
    categoria_id: nil,
    marca_id: nil,
    limite: MAX_CANDIDATOS
  )
    presupuesto_decimal = BigDecimal(presupuesto.to_s)

    catalogo_disponible(limite: 100)
      .select do |articulo|
        articulo[:precio_final] <= presupuesto_decimal.to_f &&
          coincide_filtro?(articulo[:categoria][:id], categoria_id) &&
          coincide_filtro?(articulo[:marca][:id], marca_id)
      end
      .sort_by do |articulo|
        [
          -articulo[:calificacion_promedio].to_f,
          articulo[:precio_final].to_f,
          -articulo[:stock].to_i
        ]
      end
      .first(limite)
  end

  private

  def articulos_disponibles(limite:)
    Articulo
      .includes(:categoria, :marca, :promociones, :resenas)
      .joins(:categoria, :marca)
      .where("articulos.stock > 0")
      .where(categorias: { activa: true })
      .where(marcas: { activa: true })
      .order(:id)
      .limit(limite)
  end

  def serializar_articulo(articulo)
    promocion = articulo.mejor_promocion_vigente
    calificaciones = articulo.resenas.map(&:calificacion)
    promedio = if calificaciones.any?
                 calificaciones.sum.to_f / calificaciones.length
               else
                 0.0
               end

    {
      id: articulo.id,
      nombre: articulo.nombre,
      descripcion: articulo.descripcion.to_s.truncate(240),
      categoria: {
        id: articulo.categoria.id,
        nombre: articulo.categoria.nombre
      },
      marca: {
        id: articulo.marca.id,
        nombre: articulo.marca.nombre
      },
      precio_original: articulo.precio.to_f,
      precio_final: articulo.precio_final.to_f,
      stock: articulo.stock,
      calificacion_promedio: promedio.round(2),
      total_resenas: calificaciones.length,
      promocion: promocion && {
        id: promocion.id,
        nombre: promocion.nombre,
        tipo_descuento: promocion.tipo_descuento,
        valor: promocion.valor.to_f
      }
    }
  end

  def coincide_filtro?(valor, filtro)
    filtro.blank? || valor.to_i == filtro.to_i
  end
end
