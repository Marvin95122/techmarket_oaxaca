class DashboardController < ApplicationController
  before_action :autenticar_usuario!
  before_action :solo_administrador!

  def resumen
    fecha_inicio = convertir_fecha(params[:fecha_inicio]) || 30.days.ago.to_date
    fecha_fin = convertir_fecha(params[:fecha_fin]) || Date.current

    if fecha_inicio > fecha_fin
      return render json: {
        mensaje: "La fecha de inicio no puede ser posterior a la fecha final"
      }, status: :bad_request
    end

    rango = fecha_inicio.beginning_of_day..fecha_fin.end_of_day
    compras_pagadas = Compra.where(estado: "pagada", created_at: rango)

    total_ventas = compras_pagadas.sum(:total)
    total_compras = compras_pagadas.count
    ticket_promedio = total_compras.positive? ? (total_ventas / total_compras).round(2) : 0

    productos_mas_vendidos = CompraItem.joins(:compra, :articulo)
                                         .where(compras: { estado: "pagada", created_at: rango })
                                         .group("articulos.id", "articulos.nombre")
                                         .order(Arel.sql("SUM(compra_items.cantidad) DESC"))
                                         .limit(5)
                                         .pluck(
                                           "articulos.id",
                                           "articulos.nombre",
                                           Arel.sql("SUM(compra_items.cantidad)"),
                                           Arel.sql("SUM(compra_items.subtotal)")
                                         )

    productos_mas_valorados = Resena.joins(:articulo)
                                    .group("articulos.id", "articulos.nombre")
                                    .order(Arel.sql("AVG(resenas.calificacion) DESC"), Arel.sql("COUNT(resenas.id) DESC"))
                                    .limit(5)
                                    .pluck(
                                      "articulos.id",
                                      "articulos.nombre",
                                      Arel.sql("ROUND(AVG(resenas.calificacion)::numeric, 2)"),
                                      Arel.sql("COUNT(resenas.id)")
                                    )

    ventas_por_dia = compras_pagadas.group("DATE(created_at)")
                                    .order(Arel.sql("DATE(created_at) ASC"))
                                    .pluck(
                                      Arel.sql("DATE(created_at)"),
                                      Arel.sql("SUM(total)")
                                    )

    ventas_por_categoria = CompraItem.joins(:compra, articulo: :categoria)
                                     .where(compras: { estado: "pagada", created_at: rango })
                                     .group("categorias.id", "categorias.nombre")
                                     .order(Arel.sql("SUM(compra_items.subtotal) DESC"))
                                     .pluck(
                                       "categorias.id",
                                       "categorias.nombre",
                                       Arel.sql("SUM(compra_items.subtotal)")
                                     )

    render json: {
      mensaje: "Dashboard administrativo generado correctamente",
      periodo: {
        fecha_inicio: fecha_inicio,
        fecha_fin: fecha_fin
      },
      indicadores: {
        total_ventas: total_ventas,
        total_compras: total_compras,
        ticket_promedio: ticket_promedio,
        total_articulos: Articulo.count,
        articulos_sin_stock: Articulo.where(stock: 0).count,
        articulos_stock_bajo: Articulo.where(stock: 1..5).count,
        usuarios_activos: Usuario.activos.count,
        usuarios_deshabilitados: Usuario.deshabilitados.count,
        pedidos_pagados: Compra.where(estado: "pagada").count,
        pedidos_cancelados: Compra.where(estado: "cancelada").count,
        promociones_vigentes: Promocion.vigentes.count
      },
      productos_mas_vendidos: productos_mas_vendidos.map do |id, nombre, cantidad, importe|
        {
          articulo_id: id,
          nombre: nombre,
          cantidad_vendida: cantidad,
          importe_vendido: importe
        }
      end,
      productos_mas_valorados: productos_mas_valorados.map do |id, nombre, promedio, total_resenas|
        {
          articulo_id: id,
          nombre: nombre,
          calificacion_promedio: promedio,
          total_resenas: total_resenas
        }
      end,
      ventas_por_dia: ventas_por_dia.map do |fecha, total|
        { fecha: fecha, total: total }
      end,
      ventas_por_categoria: ventas_por_categoria.map do |id, nombre, total|
        { categoria_id: id, categoria: nombre, total: total }
      end
    }, status: :ok
  rescue ArgumentError
    render json: {
      mensaje: "Formato de fecha inválido. Usa YYYY-MM-DD"
    }, status: :bad_request
  end

  private

  def convertir_fecha(valor)
    return nil if valor.blank?

    Date.iso8601(valor)
  end
end
