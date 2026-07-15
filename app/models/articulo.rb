class Articulo < ApplicationRecord
  belongs_to :categoria,
             class_name: "Categoria",
             foreign_key: :categoria_id

  belongs_to :marca,
             class_name: "Marca",
             foreign_key: :marca_id

  has_many :resenas,
           dependent: :destroy

  has_many :carrito_items,
           dependent: :destroy

  has_many :compra_items,
           dependent: :restrict_with_error

  has_many :articulo_promociones,
           class_name: "ArticuloPromocion",
           foreign_key: :articulo_id,
           dependent: :destroy,
           inverse_of: :articulo

  has_many :promociones,
           through: :articulo_promociones,
           source: :promocion

  validates :nombre, presence: true
  validates :descripcion, presence: true
  validates :precio,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }
  validates :stock,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0
            }

  def mejor_promocion_vigente
    promociones.vigentes.max_by do |promocion|
      promocion.descuento_para(precio)
    end
  end

  def precio_final
    promocion = mejor_promocion_vigente
    promocion ? promocion.precio_final(precio) : precio
  end
end
