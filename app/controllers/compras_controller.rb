class ComprasController < ApplicationController
  class PagoError < StandardError; end

  before_action :autenticar_usuario!
  before_action :usuario_o_administrador!
  before_action :solo_administrador!, only: [:actualizar_estado_envio]
  before_action :buscar_compra,
                only: [
                  :show,
                  :cancelar,
                  :actualizar_estado_envio,
                  :simular_pago_oxxo
                ]

  def index
    compras =
      if usuario_actual.administrador?
        Compra
          .includes(:usuario, compra_items: :articulo)
          .order(created_at: :desc)
      else
        usuario_actual
          .compras
          .includes(compra_items: :articulo)
          .order(created_at: :desc)
      end

    if usuario_actual.administrador?
      compras = compras.where(estado: params[:estado]) if params[:estado].present?
      compras = compras.where(estado_envio: params[:estado_envio]) if params[:estado_envio].present?
      compras = compras.where(metodo_pago: params[:metodo_pago]) if params[:metodo_pago].present?
      compras = compras.where(usuario_id: params[:usuario_id]) if params[:usuario_id].present?
    end

    render json: {
      mensaje: "Listado de compras",
      total: compras.count,
      compras: compras.map { |compra| formato_compra(compra) }
    }, status: :ok
  end

  def show
    unless usuario_actual.administrador? || @compra.usuario_id == usuario_actual.id
      return render json: {
        mensaje: "Solo puedes ver tus propias compras."
      }, status: :forbidden
    end

    render json: formato_compra(@compra), status: :ok
  end

  def create
    items = usuario_actual.carrito_items.includes(articulo: :promociones)

    if items.empty?
      return render json: {
        mensaje: "El carrito está vacío"
      }, status: :bad_request
    end

    metodo_pago = params[:metodo_pago].to_s

    unless Compra::METODOS_PAGO.include?(metodo_pago)
      return render json: {
        mensaje: "Selecciona un método de pago válido: tarjeta u OXXO."
      }, status: :unprocessable_entity
    end

    atributos_pago = construir_atributos_pago!(metodo_pago)
    compra = nil

    Compra.transaction do
      items.each do |item|
        item.articulo.lock!

        if item.cantidad > item.articulo.stock
          raise PagoError, "Stock insuficiente para #{item.articulo.nombre}"
        end
      end

      total = items.sum do |item|
        item.cantidad * item.articulo.precio_final
      end

      compra = Compra.create!(
        usuario: usuario_actual,
        total: total,
        estado_envio: "pendiente",
        **atributos_pago
      )

      items.each do |item|
        articulo = item.articulo
        precio_unitario = articulo.precio_final
        subtotal = item.cantidad * precio_unitario

        compra.compra_items.create!(
          articulo: articulo,
          cantidad: item.cantidad,
          precio_unitario: precio_unitario,
          subtotal: subtotal
        )

        # Tanto el pago con tarjeta como la referencia OXXO reservan el stock.
        articulo.update!(stock: articulo.stock - item.cantidad)
      end

      items.destroy_all
    end

    render json: {
      mensaje: mensaje_compra_creada(compra),
      compra: formato_compra(compra)
    }, status: :created
  rescue PagoError => error
    render json: {
      mensaje: "No se pudo procesar el pago",
      error: error.message
    }, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => error
    render json: {
      mensaje: "No se pudo registrar la compra",
      error: error.record.errors.full_messages.join(", ")
    }, status: :unprocessable_entity
  rescue StandardError => error
    render json: {
      mensaje: "No se pudo realizar la compra",
      error: error.message
    }, status: :bad_request
  end

  def simular_pago_oxxo
    unless usuario_actual.administrador? || @compra.usuario_id == usuario_actual.id
      return render json: {
        mensaje: "Solo puedes confirmar el pago de tus propias compras."
      }, status: :forbidden
    end

    unless @compra.pago_en_oxxo?
      return render json: {
        mensaje: "Esta compra no utiliza pago en OXXO."
      }, status: :unprocessable_entity
    end

    if @compra.cancelada?
      return render json: {
        mensaje: "No se puede pagar una compra cancelada."
      }, status: :unprocessable_entity
    end

    if @compra.pagada?
      return render json: {
        mensaje: "La compra ya se encuentra pagada.",
        compra: formato_compra(@compra)
      }, status: :ok
    end

    if @compra.pago_oxxo_vencido?
      return render json: {
        mensaje: "La referencia de pago OXXO ya venció. Cancela la compra y genera una nueva."
      }, status: :unprocessable_entity
    end

    @compra.update!(
      estado: "pagada",
      pago_confirmado_en: Time.current,
      autorizacion_pago: generar_autorizacion("OXXO")
    )

    render json: {
      mensaje: "Pago en OXXO confirmado correctamente.",
      compra: formato_compra(@compra.reload)
    }, status: :ok
  end

  def cancelar
    unless usuario_actual.administrador? || @compra.usuario_id == usuario_actual.id
      return render json: {
        mensaje: "Solo puedes cancelar tus propias compras."
      }, status: :forbidden
    end

    if @compra.cancelada?
      return render json: {
        mensaje: "La compra ya se encuentra cancelada."
      }, status: :unprocessable_entity
    end

    if @compra.entregada?
      return render json: {
        mensaje: "Una compra entregada ya no puede cancelarse."
      }, status: :unprocessable_entity
    end

    if usuario_actual.usuario_normal? && !@compra.envio_pendiente?
      return render json: {
        mensaje: "El cliente solo puede cancelar antes de que el pedido salga a reparto."
      }, status: :unprocessable_entity
    end

    actor = usuario_actual.administrador? ? "administrador" : "cliente"
    motivo_por_defecto =
      actor == "administrador" ? "Cancelación administrativa" : "Cancelación solicitada por el cliente"

    Compra.transaction do
      @compra.lock!

      @compra.compra_items.includes(:articulo).each do |item|
        item.articulo.with_lock do
          item.articulo.update!(stock: item.articulo.stock + item.cantidad)
        end
      end

      @compra.update!(
        estado: "cancelada",
        estado_envio: "cancelado",
        cancelada_en: Time.current,
        cancelada_por: actor,
        motivo_cancelacion: params[:motivo].presence || motivo_por_defecto
      )

      eliminar_resenas_sin_compra_pagada!(@compra)
    end

    render json: {
      mensaje: "Compra cancelada y stock restaurado correctamente",
      compra: formato_compra(@compra.reload)
    }, status: :ok
  end

  def actualizar_estado_envio
    if @compra.cancelada?
      return render json: {
        mensaje: "No se puede actualizar el envío de una compra cancelada."
      }, status: :unprocessable_entity
    end

    unless @compra.pagada?
      return render json: {
        mensaje: "El pedido debe estar pagado antes de iniciar el envío."
      }, status: :unprocessable_entity
    end

    if @compra.entregada?
      return render json: {
        mensaje: "El pedido ya fue entregado."
      }, status: :unprocessable_entity
    end

    nuevo_estado = params[:estado_envio].to_s
    siguiente_estado = siguiente_estado_envio(@compra)

    unless nuevo_estado == siguiente_estado
      return render json: {
        mensaje: "Transición de envío inválida.",
        estado_actual: @compra.estado_envio,
        estado_permitido: siguiente_estado
      }, status: :unprocessable_entity
    end

    atributos = {
      estado_envio: nuevo_estado
    }

    atributos[:en_transito_en] = Time.current if nuevo_estado == "en_transito"
    atributos[:entregada_en] = Time.current if nuevo_estado == "entregado"

    @compra.update!(atributos)

    render json: {
      mensaje: mensaje_actualizacion_envio(nuevo_estado),
      compra: formato_compra(@compra.reload)
    }, status: :ok
  end

  private

  def buscar_compra
    @compra =
      Compra
        .includes(:usuario, compra_items: :articulo)
        .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      mensaje: "Compra no encontrada"
    }, status: :not_found
  end

  def construir_atributos_pago!(metodo_pago)
    case metodo_pago
    when "tarjeta"
      datos = params[:datos_tarjeta] || {}
      numero = datos[:numero].to_s.gsub(/\D/, "")
      titular = datos[:titular].to_s.strip
      vencimiento = datos[:vencimiento].to_s.strip
      cvv = datos[:cvv].to_s.gsub(/\D/, "")

      raise PagoError, "Escribe el nombre del titular de la tarjeta." if titular.blank?
      raise PagoError, "El número de tarjeta no es válido." unless numero_tarjeta_valido?(numero)
      raise PagoError, "La fecha de vencimiento debe tener el formato MM/AA y no estar vencida." unless vencimiento_valido?(vencimiento)
      raise PagoError, "El CVV debe contener 3 o 4 números." unless cvv.match?(/\A\d{3,4}\z/)

      {
        metodo_pago: "tarjeta",
        estado: "pagada",
        pago_confirmado_en: Time.current,
        tarjeta_ultimos4: numero.last(4),
        tarjeta_marca: detectar_marca_tarjeta(numero),
        autorizacion_pago: generar_autorizacion("CARD")
      }
    when "oxxo"
      {
        metodo_pago: "oxxo",
        estado: "pendiente",
        referencia_pago: generar_referencia_oxxo,
        codigo_barras: generar_codigo_barras,
        pago_expira_en: 3.days.from_now
      }
    end
  end

  def numero_tarjeta_valido?(numero)
    return false unless numero.match?(/\A\d{13,19}\z/)

    suma = numero.reverse.chars.map(&:to_i).each_with_index.sum do |digito, indice|
      if indice.odd?
        duplicado = digito * 2
        duplicado > 9 ? duplicado - 9 : duplicado
      else
        digito
      end
    end

    (suma % 10).zero?
  end

  def vencimiento_valido?(vencimiento)
    coincidencia = vencimiento.match(/\A(0[1-9]|1[0-2])\/(\d{2})\z/)
    return false unless coincidencia

    mes = coincidencia[1].to_i
    anio = 2000 + coincidencia[2].to_i

    Date.new(anio, mes, -1) >= Date.current
  rescue Date::Error
    false
  end

  def detectar_marca_tarjeta(numero)
    return "Visa" if numero.start_with?("4")

    primeros_dos = numero.first(2).to_i
    primeros_cuatro = numero.first(4).to_i

    if primeros_dos.between?(51, 55) || primeros_cuatro.between?(2221, 2720)
      "Mastercard"
    else
      "Tarjeta"
    end
  end

  def generar_referencia_oxxo
    loop do
      referencia = SecureRandom.random_number(10**14).to_s.rjust(14, "0")
      return referencia unless Compra.exists?(referencia_pago: referencia)
    end
  end

  def generar_codigo_barras
    loop do
      codigo = SecureRandom.random_number(10**18).to_s.rjust(18, "0")
      return codigo unless Compra.exists?(codigo_barras: codigo)
    end
  end

  def generar_autorizacion(prefijo)
    "#{prefijo}-#{SecureRandom.hex(5).upcase}"
  end

  def mensaje_compra_creada(compra)
    if compra.pago_con_tarjeta?
      "Pago con tarjeta aprobado y compra registrada correctamente."
    else
      "Referencia OXXO generada. La compra permanecerá pendiente hasta confirmar el pago."
    end
  end

  def siguiente_estado_envio(compra)
    case compra.estado_envio
    when "pendiente"
      "en_transito"
    when "en_transito"
      "entregado"
    end
  end

  def mensaje_actualizacion_envio(estado_envio)
    case estado_envio
    when "en_transito"
      "El pedido ahora se encuentra en tránsito."
    when "entregado"
      "El pedido fue marcado como entregado."
    else
      "Estado de envío actualizado correctamente."
    end
  end

  def puede_confirmar_pago_oxxo?(compra)
    return false unless compra.pago_en_oxxo? && compra.pendiente?
    return false if compra.cancelada? || compra.pago_oxxo_vencido?

    usuario_actual.administrador? || compra.usuario_id == usuario_actual.id
  end

  def puede_cancelar_compra?(compra)
    return false if compra.cancelada? || compra.entregada? || compra.envio_cancelado?
    return true if usuario_actual.administrador?

    compra.usuario_id == usuario_actual.id && compra.envio_pendiente?
  end

  def puede_actualizar_envio?(compra)
    usuario_actual.administrador? &&
      compra.pagada? &&
      !compra.cancelada? &&
      !compra.entregada? &&
      !compra.envio_cancelado?
  end

  def eliminar_resenas_sin_compra_pagada!(compra)
    articulo_ids = compra.compra_items.map(&:articulo_id).uniq

    articulo_ids.each do |articulo_id|
      conserva_compra_pagada =
        Compra
          .where(usuario_id: compra.usuario_id, estado: "pagada")
          .joins(:compra_items)
          .where(compra_items: { articulo_id: articulo_id })
          .exists?

      next if conserva_compra_pagada

      Resena
        .where(
          usuario_id: compra.usuario_id,
          articulo_id: articulo_id
        )
        .destroy_all
    end
  end

  def formato_compra(compra)
    articulo_ids = compra.compra_items.map(&:articulo_id).uniq

    resenas_por_articulo =
      Resena
        .where(
          usuario_id: compra.usuario_id,
          articulo_id: articulo_ids
        )
        .index_by(&:articulo_id)

    compra_pagada = compra.pagada?

    {
      id: compra.id,
      total: compra.total,
      estado: compra.estado,
      estado_envio: compra.estado_envio,
      metodo_pago: compra.metodo_pago,
      referencia_pago: compra.referencia_pago,
      codigo_barras: compra.codigo_barras,
      pago_confirmado_en: compra.pago_confirmado_en,
      pago_expira_en: compra.pago_expira_en,
      pago_oxxo_vencido: compra.pago_oxxo_vencido?,
      tarjeta_ultimos4: compra.tarjeta_ultimos4,
      tarjeta_marca: compra.tarjeta_marca,
      autorizacion_pago: compra.autorizacion_pago,
      fecha: compra.created_at,
      cancelada_en: compra.cancelada_en,
      cancelada_por: compra.cancelada_por,
      motivo_cancelacion: compra.motivo_cancelacion,
      en_transito_en: compra.en_transito_en,
      entregada_en: compra.entregada_en,
      puede_confirmar_pago_oxxo: puede_confirmar_pago_oxxo?(compra),
      puede_cancelar: puede_cancelar_compra?(compra),
      puede_actualizar_envio: puede_actualizar_envio?(compra),
      siguiente_estado_envio: siguiente_estado_envio(compra),
      usuario: {
        id: compra.usuario.id,
        nombre: compra.usuario.nombre,
        correo: compra.usuario.correo
      },
      items: compra.compra_items.map do |item|
        resena = resenas_por_articulo[item.articulo_id]

        {
          id: item.id,
          articulo_id: item.articulo_id,
          nombre: item.articulo.nombre,
          cantidad: item.cantidad,
          precio_unitario: item.precio_unitario,
          subtotal: item.subtotal,
          puede_resenar: compra_pagada && resena.nil?,
          resenado: compra_pagada && resena.present?,
          resena_id: compra_pagada ? resena&.id : nil
        }
      end
    }
  end
end
