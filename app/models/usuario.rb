class Usuario < ApplicationRecord
  has_secure_password

  ROLES = ["invitado", "usuario", "administrador"].freeze

  has_many :resenas, dependent: :destroy
  has_many :carrito_items, dependent: :destroy
  has_many :compras, dependent: :destroy
  has_many :consultas_ia, class_name: "ConsultaIa", dependent: :nullify

  validates :nombre, presence: true
  validates :correo, presence: true, uniqueness: { case_sensitive: false }
  validates :rol, presence: true, inclusion: { in: ROLES }

  before_validation :normalizar_correo

  scope :activos, -> { where(activo: true) }
  scope :deshabilitados, -> { where(activo: false) }

  def administrador?
    rol == "administrador"
  end

  def usuario_normal?
    rol == "usuario"
  end

  def invitado?
    rol == "invitado"
  end

  def as_json(options = {})
    super({
      except: [:password_digest],
      methods: []
    }.merge(options))
  end

  private

  def normalizar_correo
    self.correo = correo.to_s.strip.downcase
  end
end
