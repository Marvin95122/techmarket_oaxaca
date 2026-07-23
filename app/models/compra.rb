class Compra < ApplicationRecord
  belongs_to :usuario
  has_many :compra_items, dependent: :destroy

  ESTADOS = ["pagada", "pendiente", "cancelada"].freeze
  ESTADOS_ENVIO = ["pendiente", "en_transito", "entregado", "cancelado"].freeze
  METODOS_PAGO = ["tarjeta", "oxxo"].freeze
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

  validates :metodo_pago,
            presence: true,
            inclusion: { in: METODOS_PAGO }

  validates :cancelada_por,
            inclusion: { in: ACTORES_CANCELACION },
            allow_nil: true

  validates :referencia_pago,
            uniqueness: true,
            allow_nil: true

  validates :codigo_barras,
            uniqueness: true,
            allow_nil: true

  validate :validar_datos_del_metodo_pago

  def pagada?
    estado == "pagada"
  end

  def pendiente?
    estado == "pendiente"
  end

  def cancelada?
    estado == "cancelada"
  end

  def pago_con_tarjeta?
    metodo_pago == "tarjeta"
  end

  def pago_en_oxxo?
    metodo_pago == "oxxo"
  end

  def pago_oxxo_vencido?
    pago_en_oxxo? &&
      pendiente? &&
      pago_expira_en.present? &&
      pago_expira_en < Time.current
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

  private

  def validar_datos_del_metodo_pago
    if pago_con_tarjeta?
      errors.add(:pago_confirmado_en, "debe existir para el pago con tarjeta") if pago_confirmado_en.blank?
      errors.add(:tarjeta_ultimos4, "debe contener los últimos cuatro dígitos") if tarjeta_ultimos4.blank?
      errors.add(:tarjeta_marca, "debe indicar la marca de la tarjeta") if tarjeta_marca.blank?
      errors.add(:autorizacion_pago, "debe contener una autorización de pago") if autorizacion_pago.blank?
    elsif pago_en_oxxo?
      errors.add(:referencia_pago, "debe existir para el pago en OXXO") if referencia_pago.blank?
      errors.add(:codigo_barras, "debe existir para el pago en OXXO") if codigo_barras.blank?
      errors.add(:pago_expira_en, "debe indicar la vigencia de la referencia") if pago_expira_en.blank?
    end
  end
end
