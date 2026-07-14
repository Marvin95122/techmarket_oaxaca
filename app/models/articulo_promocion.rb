class ArticuloPromocion < ApplicationRecord
  self.table_name = "articulo_promociones"

  belongs_to :articulo,
             class_name: "Articulo",
             foreign_key: :articulo_id

  belongs_to :promocion,
             class_name: "Promocion",
             foreign_key: :promocion_id

  validates :articulo_id,
            uniqueness: {
              scope: :promocion_id,
              message: "ya tiene asignada esta promoción"
            }
end