require "json"
require "net/http"
require "openssl"
require "uri"

class GeminiService
  API_URL = "https://generativelanguage.googleapis.com/v1/interactions".freeze
  DEFAULT_MODEL = "gemini-3.5-flash".freeze

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
    temperatura: 1.0,
    max_tokens: 900
  )
    validar_configuracion!

    uri = URI.parse(@api_url)
    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "application/json"
    request["x-goog-api-key"] = @api_key
    request.body = {
      model: model,
      input: entrada,
      system_instruction: instruccion_sistema,
      store: false,
      generation_config: {
        temperature: temperatura,
        max_output_tokens: max_tokens
      }
    }.to_json

    response = ejecutar_solicitud(uri, request)
    data = parsear_json(response.body)

    unless response.is_a?(Net::HTTPSuccess)
      raise RequestError.new(
        mensaje_amigable(response.code.to_i, data),
        provider_status: response.code.to_i,
        details: data.dig("error", "message")
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
    {}
  end

  def extraer_texto(data)
    Array(data["steps"]).flat_map do |step|
      next [] unless step["type"] == "model_output"

      Array(step["content"]).filter_map do |content|
        content["text"] if content["type"] == "text"
      end
    end.join("\n").strip
  end

  def mensaje_amigable(status, data)
    provider_message = data.dig("error", "message").to_s

    case status
    when 400
      "Gemini rechazó la solicitud. Revisa el modelo y los datos enviados."
    when 401, 403
      "La clave de Gemini no es válida o no tiene permisos suficientes."
    when 404
      "El modelo de Gemini configurado no está disponible para esta cuenta."
    when 429
      "Se alcanzó temporalmente el límite de solicitudes de Gemini."
    when 500..599
      "Gemini no está disponible temporalmente."
    else
      provider_message.presence || "Gemini devolvió una respuesta inesperada."
    end
  end
end
