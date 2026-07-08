class CarritoItem < ApplicationRecord
  belongs_to :usuario
  belongs_to :articulo

  validates :cantidad, presence: true, numericality: {
    only_integer: true,
    greater_than: 0
  }

  validates :usuario_id, uniqueness: {
    scope: :articulo_id,
    message: "ya tiene este artículo en el carrito"
  }
end