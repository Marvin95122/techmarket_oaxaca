class Categoria < ApplicationRecord
  self.table_name = "categorias"

  has_many :articulos, dependent: :restrict_with_error

  validates :nombre,
            presence: true,
            uniqueness: { case_sensitive: false }

  before_validation :normalizar_nombre

  private

  def normalizar_nombre
    self.nombre = nombre.to_s.strip
  end
end