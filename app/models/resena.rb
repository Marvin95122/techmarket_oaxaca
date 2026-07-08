class Resena < ApplicationRecord
  belongs_to :usuario
  belongs_to :articulo

  validates :calificacion, presence: true, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: 5
  }

  validates :comentario, presence: true
  validates :usuario_id, uniqueness: {
    scope: :articulo_id,
    message: "ya hizo una reseña para este artículo"
  }
end