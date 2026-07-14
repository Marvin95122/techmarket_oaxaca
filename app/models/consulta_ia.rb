class ConsultaIa < ApplicationRecord
  self.table_name = "consultas_ia"

  TIPOS = ["chatbot", "recomendacion", "personalizacion"].freeze

  belongs_to :usuario, optional: true

  validates :tipo, presence: true, inclusion: { in: TIPOS }
  validates :pregunta, presence: true
  validates :respuesta, presence: true
end
