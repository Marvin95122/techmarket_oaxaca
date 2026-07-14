class Promocion < ApplicationRecord
  self.table_name = "promociones"

  TIPOS_DESCUENTO = [
    "porcentaje",
    "monto_fijo"
  ].freeze

  has_many :articulo_promociones,
           class_name: "ArticuloPromocion",
           foreign_key: :promocion_id,
           dependent: :destroy,
           inverse_of: :promocion

  has_many :articulos,
           through: :articulo_promociones,
           source: :articulo

  validates :nombre,
            presence: true

  validates :tipo_descuento,
            presence: true,
            inclusion: {
              in: TIPOS_DESCUENTO
            }

  validates :valor,
            presence: true,
            numericality: {
              greater_than: 0
            }

  validates :fecha_inicio,
            presence: true

  validates :fecha_fin,
            presence: true

  validates :codigo,
            uniqueness: {
              case_sensitive: false
            },
            allow_nil: true

  validate :fecha_fin_posterior_a_fecha_inicio
  validate :porcentaje_valido

  before_validation :normalizar_codigo

  scope :activas, -> {
    where(activa: true)
  }

  scope :vigentes, -> {
    activas.where(
      "fecha_inicio <= ? AND fecha_fin >= ?",
      Time.current,
      Time.current
    )
  }

  def vigente?
    activa? &&
      fecha_inicio <= Time.current &&
      fecha_fin >= Time.current
  end

  def descuento_para(precio)
    precio_decimal = BigDecimal(precio.to_s)

    descuento =
      if tipo_descuento == "porcentaje"
        precio_decimal * (valor / 100)
      else
        valor
      end

    [descuento, precio_decimal].min
  end

  def precio_final(precio)
    precio_decimal = BigDecimal(precio.to_s)

    (
      precio_decimal - descuento_para(precio_decimal)
    ).round(2)
  end

  private

  def normalizar_codigo
    self.codigo = codigo.to_s.strip.upcase.presence
  end

  def fecha_fin_posterior_a_fecha_inicio
    return if fecha_inicio.blank? || fecha_fin.blank?
    return if fecha_fin > fecha_inicio

    errors.add(
      :fecha_fin,
      "debe ser posterior a la fecha de inicio"
    )
  end

  def porcentaje_valido
    return unless tipo_descuento == "porcentaje"
    return if valor.blank? || valor <= 100

    errors.add(
      :valor,
      "no puede ser mayor a 100 cuando el descuento es porcentaje"
    )
  end
end