class Articulo < ApplicationRecord
  validates :nombre, presence: true
  validates :descripcion, presence: true
  validates :precio, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :stock, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :categoria, presence: true
end