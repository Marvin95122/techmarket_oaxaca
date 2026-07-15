class Compra < ApplicationRecord
  belongs_to :usuario
  has_many :compra_items, dependent: :destroy

  ESTADOS = ["pagada", "pendiente", "cancelada"].freeze

  validates :total,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }
  validates :estado, presence: true, inclusion: { in: ESTADOS }

  def cancelada?
    estado == "cancelada"
  end
end
