require "json"
require "net/http"
require "openssl"
require "uri"

class GeminiService
  API_URL = "https://generativelanguage.googleapis.com/v1/interactions".freeze
  DEFAULT_MODEL = "gemini-3.5-flash".freeze
  THINKING_LEVELS = %w[minimal low medium high].freeze

  class Error < StandardError
    attr_reader :provider_status, :details

    def initialize(message, provider_status: nil, details: nil)
      super(message)
      @provider_status = provider_status
      @details = details
    end
  end

  class ConfigurationError < Error; end
  class RequestError < Error; end

  attr_reader :model

  def initialize(
    api_key: ENV["GEMINI_API_KEY"],
    model: ENV.fetch("GEMINI_MODEL", DEFAULT_MODEL),
    api_url: ENV.fetch("GEMINI_API_URL", API_URL)
  )
    @api_key = api_key.to_s.strip
    @model = model.to_s.strip.presence || DEFAULT_MODEL
    @api_url = api_url.to_s.strip.presence || API_URL
  end

  def configured?
    @api_key.present?
  end

  def generar(
    entrada:,
    instruccion_sistema:,
    max_tokens: 900,
    thinking_level: "low"
  )
    validar_configuracion!

    uri = URI.parse(@api_url)
    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "application/json"
    request["x-goog-api-key"] = @api_key
    request.body = construir_cuerpo(
      entrada: entrada,
      instruccion_sistema: instruccion_sistema,
      max_tokens: max_tokens,
      thinking_level: thinking_level
    ).to_json

    response = ejecutar_solicitud(uri, request)
    data = parsear_json(response.body)

    unless response.is_a?(Net::HTTPSuccess)
      detalle = extraer_mensaje_error(data, response.body)

      Rails.logger.error(
        "Gemini HTTP #{response.code}: #{detalle}"
      ) if defined?(Rails)

      raise RequestError.new(
        mensaje_amigable(response.code.to_i, detalle),
        provider_status: response.code.to_i,
        details: detalle
      )
    end

    texto = extraer_texto(data)

    if texto.blank?
      raise RequestError.new(
        "Gemini respondió, pero no devolvió texto utilizable.",
        provider_status: response.code.to_i,
        details: data
      )
    end

    {
      texto: texto,
      interaction_id: data["id"],
      modelo: data["model"].presence || model,
      estado: data["status"],
      uso: data["usage"] || {}
    }
  rescue URI::InvalidURIError
    raise ConfigurationError,
          "La dirección configurada para Gemini no es válida."
  rescue Net::OpenTimeout, Net::ReadTimeout
    raise RequestError,
          "Gemini tardó demasiado en responder. Intenta nuevamente."
  rescue SocketError, Errno::ECONNREFUSED, OpenSSL::SSL::SSLError => error
    raise RequestError.new(
      "No fue posible establecer comunicación segura con Gemini.",
      details: error.message
    )
  end

  private

  def validar_configuracion!
    return if configured?

    raise ConfigurationError,
          "La API de IA no está configurada. Define GEMINI_API_KEY."
  end

  def construir_cuerpo(
    entrada:,
    instruccion_sistema:,
    max_tokens:,
    thinking_level:
  )
    nivel = thinking_level.to_s
    nivel = "low" unless THINKING_LEVELS.include?(nivel)

    {
      model: model,
      input: entrada,
      system_instruction: instruccion_sistema,
      store: false,
      generation_config: {
        max_output_tokens: max_tokens.to_i,
        thinking_level: nivel
      }
    }
  end

  def ejecutar_solicitud(uri, request)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 10
    http.read_timeout = 60
    http.write_timeout = 15 if http.respond_to?(:write_timeout=)
    http.request(request)
  end

  def parsear_json(body)
    JSON.parse(body.to_s)
  rescue JSON::ParserError
    { "raw_body" => body.to_s }
  end

  def extraer_texto(data)
    return "" unless data.is_a?(Hash)

    Array(data["steps"]).flat_map do |step|
      next [] unless step.is_a?(Hash)
      next [] unless step["type"] == "model_output"

      Array(step["content"]).filter_map do |content|
        next unless content.is_a?(Hash)
        next unless content["type"] == "text"

        content["text"].to_s.presence
      end
    end.join("\n").strip
  end

  def extraer_mensaje_error(data, raw_body = nil)
    mensaje =
      case data
      when Hash
        extraer_desde_hash(data)
      when Array
        extraer_desde_array(data)
      else
        data.to_s
      end

    mensaje = raw_body.to_s if mensaje.blank?
    mensaje.presence || "Gemini devolvió un error sin descripción."
  end

  def extraer_desde_hash(data)
    error = data["error"]

    case error
    when Hash
      error["message"].presence ||
        error["detail"].presence ||
        error["code"].presence ||
        error.to_json
    when Array
      extraer_desde_array(error)
    when String
      error
    else
      data["message"].presence ||
        data["detail"].presence ||
        data["raw_body"].presence ||
        data.to_json
    end
  end

  def extraer_desde_array(elementos)
    Array(elementos).filter_map do |elemento|
      case elemento
      when Hash
        elemento["message"].presence ||
          elemento["detail"].presence ||
          elemento["code"].presence ||
          elemento.to_json
      when String
        elemento.presence
      else
        elemento.to_s.presence
      end
    end.join(" | ")
  end

  def mensaje_amigable(status, provider_message)
    detalle = provider_message.to_s.strip

    encabezado =
      case status
      when 400
        "Gemini rechazó la solicitud."
      when 401, 403
        "La clave de Gemini no es válida o no tiene permisos suficientes."
      when 404
        "El modelo de Gemini configurado no está disponible para esta cuenta."
      when 429
        "Se alcanzó temporalmente el límite de solicitudes de Gemini."
      when 500..599
        "Gemini no está disponible temporalmente."
      else
        "Gemini devolvió una respuesta inesperada."
      end

    return encabezado if detalle.blank?

    "#{encabezado} Detalle del proveedor: #{detalle}"
  end
end
