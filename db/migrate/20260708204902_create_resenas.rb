class CreateResenas < ActiveRecord::Migration[8.1]
  def change
    create_table :resenas do |t|
      t.references :usuario, null: false, foreign_key: true
      t.references :articulo, null: false, foreign_key: true
      t.integer :calificacion, null: false
      t.text :comentario, null: false

      t.timestamps
    end

    add_index :resenas, [:usuario_id, :articulo_id], unique: true
  end
end