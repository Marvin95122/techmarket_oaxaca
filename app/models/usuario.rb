class Usuario < ApplicationRecord
  has_secure_password

  ROLES = ["invitado", "usuario", "administrador"]

  has_many :resenas, dependent: :destroy
  has_many :carrito_items, dependent: :destroy
  has_many :compras, dependent: :destroy

  validates :nombre, presence: true
  validates :correo, presence: true, uniqueness: true
  validates :rol, presence: true, inclusion: { in: ROLES }

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
      except: [:password_digest, :created_at, :updated_at]
    }.merge(options))
  end
end