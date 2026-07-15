class UsuariosController < ApplicationController
  before_action :autenticar_usuario!, except: [:create]
  before_action :solo_administrador!, only: [
    :index,
    :update,
    :destroy,
    :deshabilitar,
    :habilitar
  ]
  before_action :buscar_usuario, only: [
    :show,
    :update,
    :destroy,
    :deshabilitar,
    :habilitar
  ]

  def index
    usuarios = Usuario.order(:id)
    usuarios = usuarios.where(rol: params[:rol]) if params[:rol].present?

    if params[:activo].present?
      usuarios = usuarios.where(activo: ActiveModel::Type::Boolean.new.cast(params[:activo]))
    end

    if params[:buscar].present?
      termino = "%#{ActiveRecord::Base.sanitize_sql_like(params[:buscar])}%"
      usuarios = usuarios.where(
        "nombre ILIKE :termino OR correo ILIKE :termino",
        termino: termino
      )
    end

    render json: {
      mensaje: "Listado de usuarios de TechMarket Oaxaca",
      total: usuarios.count,
      usuarios: usuarios
    }, status: :ok
  end

  def show
    unless usuario_actual.administrador? || usuario_actual.id == @usuario.id
      return render json: {
        mensaje: "Solo puedes ver tu propio perfil."
      }, status: :forbidden
    end

    render json: @usuario, status: :ok
  end

  def create
    usuario = Usuario.new(usuario_params_creacion)
    usuario.rol = "usuario"
    usuario.activo = true

    if usuario.save
      render json: {
        mensaje: "Usuario registrado correctamente",
        usuario: usuario
      }, status: :created
    else
      render json: {
        mensaje: "No se pudo registrar el usuario",
        errores: usuario.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    if @usuario.update(usuario_params_admin)
      render json: {
        mensaje: "Usuario actualizado correctamente",
        usuario: @usuario
      }, status: :ok
    else
      render json: {
        mensaje: "No se pudo actualizar el usuario",
        errores: @usuario.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def deshabilitar
    if @usuario.id == usuario_actual.id
      return render json: {
        mensaje: "No puedes deshabilitar tu propia cuenta administrativa."
      }, status: :unprocessable_entity
    end

    @usuario.update!(activo: false)

    render json: {
      mensaje: "Usuario deshabilitado correctamente",
      usuario: @usuario
    }, status: :ok
  end

  def habilitar
    @usuario.update!(activo: true)

    render json: {
      mensaje: "Usuario habilitado correctamente",
      usuario: @usuario
    }, status: :ok
  end

  def destroy
    if @usuario.id == usuario_actual.id
      return render json: {
        mensaje: "No puedes eliminar tu propia cuenta administrativa."
      }, status: :unprocessable_entity
    end

    @usuario.destroy!

    render json: {
      mensaje: "Usuario eliminado correctamente",
      usuario: @usuario
    }, status: :ok
  end

  private

  def buscar_usuario
    @usuario = Usuario.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { mensaje: "Usuario no encontrado" }, status: :not_found
  end

  def usuario_params_creacion
    params.permit(:nombre, :correo, :password)
  end

  def usuario_params_admin
    params.permit(:nombre, :correo, :password, :rol)
  end
end
