class ConsultasIaController < ApplicationController
  before_action :autenticar_usuario!
  before_action :usuario_o_administrador!
  before_action :buscar_consulta, only: [:show, :destroy]

  def index
    consultas = if usuario_actual.administrador?
                  ConsultaIa.includes(:usuario).order(created_at: :desc)
                else
                  usuario_actual.consultas_ia.order(created_at: :desc)
                end

    render json: {
      mensaje: "Historial de consultas de inteligencia artificial",
      total: consultas.count,
      consultas: consultas
    }, status: :ok
  end

  def show
    unless usuario_actual.administrador? || @consulta.usuario_id == usuario_actual.id
      return render json: {
        mensaje: "No tienes permiso para ver esta consulta"
      }, status: :forbidden
    end

    render json: @consulta, status: :ok
  end

  def destroy
    unless usuario_actual.administrador? || @consulta.usuario_id == usuario_actual.id
      return render json: {
        mensaje: "No tienes permiso para eliminar esta consulta"
      }, status: :forbidden
    end

    @consulta.destroy!
    render json: { mensaje: "Consulta eliminada correctamente" }, status: :ok
  end

  private

  def buscar_consulta
    @consulta = ConsultaIa.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { mensaje: "Consulta de IA no encontrada" }, status: :not_found
  end
end
