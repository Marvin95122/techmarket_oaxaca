class UsuariosController < ApplicationController
  before_action :autenticar_usuario!, except: [:create]
  before_action :solo_administrador!, only: [:index, :update, :destroy]

  def index
    usuarios = Usuario.all.order(:id)

    render json: {
      mensaje: "Listado de usuarios de TechMarket Oaxaca",
      total: usuarios.count,
      usuarios: usuarios
    }, status: :ok
  end

  def show
    usuario = Usuario.find(params[:id])

    unless usuario_actual.administrador? || usuario_actual.id == usuario.id
      return render json: {
        mensaje: "Solo puedes ver tu propio perfil."
      }, status: :forbidden
    end

    render json: usuario, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: {
      mensaje: "Usuario no encontrado"
    }, status: :not_found
  end

  def create
    usuario = Usuario.new(usuario_params_creacion)
    usuario.rol = "usuario"

    if usuario.save
      render json: {
        mensaje: "Usuario registrado correctamente",
        usuario: usuario
      }, status: :created
    else
      render json: {
        mensaje: "No se pudo registrar el usuario",
        errores: usuario.errors.full_messages
      }, status: :bad_request
    end
  end

  def update
    usuario = Usuario.find(params[:id])

    if usuario.update(usuario_params_admin)
      render json: {
        mensaje: "Usuario actualizado correctamente",
        usuario: usuario
      }, status: :ok
    else
      render json: {
        mensaje: "No se pudo actualizar el usuario",
        errores: usuario.errors.full_messages
      }, status: :bad_request
    end
  rescue ActiveRecord::RecordNotFound
    render json: {
      mensaje: "Usuario no encontrado"
    }, status: :not_found
  end

  def destroy
    usuario = Usuario.find(params[:id])
    usuario.destroy

    render json: {
      mensaje: "Usuario eliminado correctamente",
      usuario: usuario
    }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: {
      mensaje: "Usuario no encontrado"
    }, status: :not_found
  end

  private

  def usuario_params_creacion
    params.permit(:nombre, :correo, :password)
  end

  def usuario_params_admin
    params.permit(:nombre, :correo, :password, :rol)
  end
end