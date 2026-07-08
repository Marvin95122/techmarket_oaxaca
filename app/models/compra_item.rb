class CompraItem < ApplicationRecord
  belongs_to :compra
  belongs_to :articulo

  validates :cantidad, presence: true, numericality: {
    only_integer: true,
    greater_than: 0
  }

  validates :precio_unitario, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :subtotal, presence: true, numericality: { greater_than_or_equal_to: 0 }
end