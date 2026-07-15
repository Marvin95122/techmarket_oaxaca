class AuthController < ApplicationController
  before_action :autenticar_usuario!, only: [:perfil]

  def login
    correo = params[:correo].to_s.strip.downcase
    usuario = Usuario.find_by(correo: correo)

    unless usuario&.authenticate(params[:password])
      return render json: {
        mensaje: "Correo o contraseña incorrectos"
      }, status: :unauthorized
    end

    unless usuario.activo?
      return render json: {
        mensaje: "La cuenta está deshabilitada. Contacta al administrador."
      }, status: :forbidden
    end

    token = generar_token(usuario)

    render json: {
      mensaje: "Login correcto",
      duracion: "3 minutos",
      token: token,
      usuario: usuario
    }, status: :ok
  end

  def perfil
    render json: {
      mensaje: "Perfil del usuario autenticado",
      usuario: usuario_actual
    }, status: :ok
  end
end
