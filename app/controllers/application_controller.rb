class ApplicationController < ActionController::API
  private

  def jwt_secret
    ENV.fetch("JWT_SECRET") { Rails.application.secret_key_base }
  end

  def generar_token(usuario)
    payload = {
      usuario_id: usuario.id,
      correo: usuario.correo,
      rol: usuario.rol,
      exp: 3.minutes.from_now.to_i
    }

    JWT.encode(payload, jwt_secret, "HS256")
  end

  def autenticar_usuario!
    auth_header = request.headers["Authorization"]

    unless auth_header.present?
      return render json: {
        mensaje: "Acceso denegado. No se envió token."
      }, status: :unauthorized
    end

    token = auth_header.split(" ").last

    begin
      decoded = JWT.decode(token, jwt_secret, true, { algorithm: "HS256" }).first
      @usuario_actual = Usuario.find(decoded["usuario_id"])
    rescue JWT::ExpiredSignature
      render json: {
        mensaje: "Token expirado. Inicia sesión nuevamente."
      }, status: :unauthorized
    rescue JWT::DecodeError
      render json: {
        mensaje: "Token inválido."
      }, status: :unauthorized
    rescue ActiveRecord::RecordNotFound
      render json: {
        mensaje: "Usuario del token no encontrado."
      }, status: :unauthorized
    end
  end

  def usuario_actual
    @usuario_actual
  end

  def autorizar_roles!(*roles)
    unless usuario_actual && roles.include?(usuario_actual.rol)
      return render json: {
        mensaje: "Acceso denegado. No tienes permisos para realizar esta acción."
      }, status: :forbidden
    end
  end

  def solo_administrador!
    autorizar_roles!("administrador")
  end

  def usuario_o_administrador!
    autorizar_roles!("usuario", "administrador")
  end
end