class Compra < ApplicationRecord
  belongs_to :usuario
  has_many :compra_items, dependent: :destroy

  ESTADOS = ["pagada", "pendiente", "cancelada"].freeze
  ESTADOS_ENVIO = ["pendiente", "en_transito", "entregado", "cancelado"].freeze
  ACTORES_CANCELACION = ["cliente", "administrador"].freeze

  validates :total,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  validates :estado,
            presence: true,
            inclusion: { in: ESTADOS }

  validates :estado_envio,
            presence: true,
            inclusion: { in: ESTADOS_ENVIO }

  validates :cancelada_por,
            inclusion: { in: ACTORES_CANCELACION },
            allow_nil: true

  def pagada?
    estado == "pagada"
  end

  def pendiente?
    estado == "pendiente"
  end

  def cancelada?
    estado == "cancelada"
  end

  def envio_pendiente?
    estado_envio == "pendiente"
  end

  def en_transito?
    estado_envio == "en_transito"
  end

  def entregada?
    estado_envio == "entregado"
  end

  def envio_cancelado?
    estado_envio == "cancelado"
  end
end
