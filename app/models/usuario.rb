class Usuario < ApplicationRecord
  has_secure_password

  ROLES = ["invitado", "usuario", "administrador"]

  validates :nombre, presence: true
  validates :correo, presence: true, uniqueness: true
  validates :rol, presence: true, inclusion: { in: ROLES }

  def as_json(options = {})
    super({
      except: [:password_digest, :created_at, :updated_at]
    }.merge(options))
  end
end