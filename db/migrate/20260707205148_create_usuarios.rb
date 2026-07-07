class CreateUsuarios < ActiveRecord::Migration[8.1]
  def change
    create_table :usuarios do |t|
      t.string :nombre, null: false
      t.string :correo, null: false
      t.string :password_digest, null: false
      t.string :rol, null: false, default: "usuario"

      t.timestamps
    end

    add_index :usuarios, :correo, unique: true
  end
end