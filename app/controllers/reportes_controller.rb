class ReportesController < ApplicationController
  before_action :autenticar_usuario!
  before_action :solo_administrador!

  def ventas
    fecha_inicio = convertir_fecha(params[:fecha_inicio]) || 30.days.ago.to_date
    fecha_fin = convertir_fecha(params[:fecha_fin]) || Date.current

    if fecha_inicio > fecha_fin
      return render json: {
        mensaje: "La fecha de inicio no puede ser posterior a la fecha final"
      }, status: :bad_request
    end

    rango = fecha_inicio.beginning_of_day..fecha_fin.end_of_day
    compras = Compra.where(estado: "pagada", created_at: rango)

    total_ventas = compras.sum(:total)
    total_compras = compras.count
    unidades_vendidas = CompraItem.joins(:compra)
                                  .where(compras: { estado: "pagada", created_at: rango })
                                  .sum(:cantidad)

    ticket_promedio = total_compras.positive? ? (total_ventas / total_compras).round(2) : 0

    top_articulos = CompraItem.joins(:compra, :articulo)
                              .where(compras: { estado: "pagada", created_at: rango })
                              .group("articulos.id", "articulos.nombre")
                              .order(Arel.sql("SUM(compra_items.cantidad) DESC"))
                              .limit(10)
                              .pluck(
                                "articulos.id",
                                "articulos.nombre",
                                Arel.sql("SUM(compra_items.cantidad)"),
                                Arel.sql("SUM(compra_items.subtotal)")
                              )

    ventas_por_dia = compras.group("DATE(created_at)")
                            .order(Arel.sql("DATE(created_at) ASC"))
                            .pluck(
                              Arel.sql("DATE(created_at)"),
                              Arel.sql("COUNT(*)"),
                              Arel.sql("SUM(total)")
                            )

    render json: {
      mensaje: "Reporte de ventas generado correctamente",
      periodo: {
        fecha_inicio: fecha_inicio,
        fecha_fin: fecha_fin
      },
      resumen: {
        total_ventas: total_ventas,
        total_compras: total_compras,
        unidades_vendidas: unidades_vendidas,
        ticket_promedio: ticket_promedio
      },
      top_articulos: top_articulos.map do |id, nombre, cantidad, importe|
        {
          articulo_id: id,
          nombre: nombre,
          cantidad_vendida: cantidad,
          importe_vendido: importe
        }
      end,
      ventas_por_dia: ventas_por_dia.map do |fecha, cantidad, total|
        {
          fecha: fecha,
          compras: cantidad,
          total: total
        }
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
