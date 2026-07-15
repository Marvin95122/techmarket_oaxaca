class IaController < ApplicationController
  before_action :autenticar_usuario!
  before_action :usuario_o_administrador!
  before_action :solo_administrador!, only: [:estado]

  MAX_PREGUNTA = 1_000
  MAX_USO = 300

  def estado
    servicio = GeminiService.new

    render json: {
      proveedor: "Google Gemini",
      api: "Interactions API v1",
      configurada: servicio.configured?,
      modelo: servicio.model,
      funciones: [
        {
          endpoint: "POST /ia/chat",
          descripcion: "Responde preguntas utilizando el catálogo real disponible."
        },
        {
          endpoint: "POST /ia/recomendaciones",
          descripcion: "Genera recomendaciones según presupuesto, uso, categoría y marca."
        }
      ]
    }, status: :ok
  end

  def chat
    pregunta = params[:pregunta].to_s.strip
    return render_error("Debes escribir una pregunta.") if pregunta.blank?

    if pregunta.length > MAX_PREGUNTA
      return render_error(
        "La pregunta no puede superar #{MAX_PREGUNTA} caracteres."
      )
    end

    catalogo = CatalogoIaService.new.catalogo_disponible

    if catalogo.empty?
      return render_error(
        "No existen artículos disponibles para responder la consulta."
      )
    end

    resultado = GeminiService.new.generar(
      entrada: construir_entrada_chat(pregunta, catalogo),
      instruccion_sistema: instruccion_chat,
      temperatura: 0.2,
      max_tokens: 850
    )

    consulta = guardar_consulta!(
      tipo: "chatbot",
      pregunta: pregunta,
      resultado: resultado,
      datos_contexto: {
        articulos_consultados: catalogo.map { |articulo| articulo[:id] }
      }
    )

    render json: {
      mensaje: "Consulta procesada correctamente",
      consulta_id: consulta.id,
      funcion: "chatbot_catalogo",
      proveedor: "Google Gemini",
      modelo: resultado[:modelo],
      respuesta: resultado[:texto],
      uso: resultado[:uso]
    }, status: :ok
  end

  def recomendaciones
    presupuesto = decimal_parametro(params[:presupuesto])
    uso = params[:uso].to_s.strip

    return render_error("El presupuesto debe ser mayor que cero.") unless presupuesto&.positive?
    return render_error("Debes indicar el uso que tendrá el producto.") if uso.blank?

    if uso.length > MAX_USO
      return render_error(
        "La descripción del uso no puede superar #{MAX_USO} caracteres."
      )
    end

    categoria = buscar_filtro(Categoria, params[:categoria_id], "Categoría")
    return if performed?

    marca = buscar_filtro(Marca, params[:marca_id], "Marca")
    return if performed?

    candidatos = CatalogoIaService.new.candidatos_recomendacion(
      presupuesto: presupuesto,
      categoria_id: categoria&.id,
      marca_id: marca&.id
    )

    if candidatos.empty?
      return render_error(
        "No hay productos disponibles que cumplan con los filtros y presupuesto.",
        status: :unprocessable_entity
      )
    end

    resultado = GeminiService.new.generar(
      entrada: construir_entrada_recomendacion(
        presupuesto: presupuesto,
        uso: uso,
        categoria: categoria,
        marca: marca,
        candidatos: candidatos
      ),
      instruccion_sistema: instruccion_recomendaciones,
      temperatura: 0.25,
      max_tokens: 900
    )

    pregunta_guardada = "Presupuesto: $#{format('%.2f', presupuesto)}. Uso: #{uso}"

    consulta = guardar_consulta!(
      tipo: "recomendacion",
      pregunta: pregunta_guardada,
      resultado: resultado,
      datos_contexto: {
        presupuesto: presupuesto.to_f,
        uso: uso,
        categoria_id: categoria&.id,
        marca_id: marca&.id,
        productos_candidatos: candidatos.map { |articulo| articulo[:id] }
      }
    )

    render json: {
      mensaje: "Recomendación generada correctamente",
      consulta_id: consulta.id,
      funcion: "recomendaciones_personalizadas",
      proveedor: "Google Gemini",
      modelo: resultado[:modelo],
      respuesta: resultado[:texto],
      productos_recomendados: candidatos.first(5),
      filtros: {
        presupuesto: presupuesto.to_f,
        uso: uso,
        categoria: categoria && { id: categoria.id, nombre: categoria.nombre },
        marca: marca && { id: marca.id, nombre: marca.nombre }
      },
      uso_api: resultado[:uso]
    }, status: :ok
  end

  private

  def construir_entrada_chat(pregunta, catalogo)
    <<~PROMPT
      Pregunta del cliente:
      #{pregunta}

      Catálogo disponible en formato JSON:
      #{JSON.pretty_generate(catalogo)}
    PROMPT
  end

  def construir_entrada_recomendacion(
    presupuesto:,
    uso:,
    categoria:,
    marca:,
    candidatos:
  )
    <<~PROMPT
      Necesidad del cliente:
      - Presupuesto máximo: $#{format('%.2f', presupuesto)} MXN
      - Uso principal: #{uso}
      - Categoría solicitada: #{categoria&.nombre || 'Cualquiera'}
      - Marca solicitada: #{marca&.nombre || 'Cualquiera'}

      Productos candidatos reales en formato JSON:
      #{JSON.pretty_generate(candidatos)}
    PROMPT
  end

  def instruccion_chat
    <<~INSTRUCCION
      Eres el asistente de ventas de TechMarket Oaxaca.
      Responde siempre en español claro y amable.
      Utiliza exclusivamente los productos incluidos en el catálogo proporcionado.
      No inventes productos, precios, promociones, calificaciones ni existencias.
      Cuando la pregunta no pueda responderse con el catálogo, indícalo de forma directa.
      Menciona el precio final y el stock cuando sean relevantes.
      No solicites ni expongas datos personales, contraseñas o claves de API.
    INSTRUCCION
  end

  def instruccion_recomendaciones
    <<~INSTRUCCION
      Eres un asesor tecnológico de TechMarket Oaxaca.
      Recomienda únicamente productos presentes en la lista de candidatos reales.
      Responde en español y explica por qué cada opción se adapta al uso solicitado.
      Respeta el presupuesto máximo indicado.
      Incluye nombre, precio final, stock y una comparación breve.
      No inventes especificaciones que no aparezcan en la información proporcionada.
      Si la descripción disponible no permite confirmar una característica, dilo claramente.
    INSTRUCCION
  end

  def guardar_consulta!(tipo:, pregunta:, resultado:, datos_contexto:)
    usuario_actual.consultas_ia.create!(
      tipo: tipo,
      pregunta: pregunta,
      respuesta: resultado[:texto],
      contexto: datos_contexto.merge(
        proveedor: "google_gemini",
        api: "interactions_v1",
        modelo: resultado[:modelo],
        interaction_id: resultado[:interaction_id],
        estado_proveedor: resultado[:estado],
        uso: resultado[:uso]
      )
    )
  end

  def decimal_parametro(valor)
    BigDecimal(valor.to_s)
  rescue ArgumentError
    nil
  end

  def buscar_filtro(modelo, id, nombre)
    return nil if id.blank?

    registro = modelo.find(id)

    unless registro.activa?
      render_error("#{nombre} no está activa.")
      return nil
    end

    registro
  rescue ActiveRecord::RecordNotFound
    render_error("#{nombre} no encontrada.", status: :not_found)
    nil
  end

  def render_error(mensaje, status: :unprocessable_entity)
    render json: { mensaje: mensaje }, status: status
  end

  rescue_from GeminiService::ConfigurationError do |error|
    render json: {
      mensaje: error.message,
      proveedor: "Google Gemini"
    }, status: :service_unavailable
  end

  rescue_from GeminiService::RequestError do |error|
    Rails.logger.error(
      "Error de Gemini: status=#{error.provider_status} details=#{error.details}"
    )

    render json: {
      mensaje: error.message,
      proveedor: "Google Gemini",
      codigo_proveedor: error.provider_status
    }, status: :bad_gateway
  end

  rescue_from ActiveRecord::RecordInvalid do |error|
    render json: {
      mensaje: "La respuesta se generó, pero no pudo guardarse en el historial.",
      errores: error.record.errors.full_messages
    }, status: :unprocessable_entity
  end
end
