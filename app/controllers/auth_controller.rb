class AuthController < ApplicationController
  before_action :autenticar_usuario!, only: [:perfil]

  def login
    usuario = Usuario.find_by(correo: params[:correo])

    unless usuario&.authenticate(params[:password])
      return render json: {
        mensaje: "Correo o contraseña incorrectos"
      }, status: :unauthorized
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