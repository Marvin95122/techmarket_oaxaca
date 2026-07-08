class Articulo < ApplicationRecord
  has_many :resenas, dependent: :destroy
  has_many :carrito_items, dependent: :destroy
  has_many :compra_items, dependent: :restrict_with_error

  validates :nombre, presence: true
  validates :descripcion, presence: true
  validates :precio, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :stock, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :categoria, presence: true
end