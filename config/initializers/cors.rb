CORS_ACTIVO = ENV.fetch("CORS_ACTIVO", "true") == "true"

if CORS_ACTIVO
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins "*"

      resource "*",
        headers: :any,
        methods: [:get, :post, :put, :patch, :delete, :options, :head]
    end
  end
end