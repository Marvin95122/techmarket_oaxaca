class CreateCategorias < ActiveRecord::Migration[8.1]
  def change
    create_table :categorias do |t|
      t.string :nombre, null: false
      t.text :descripcion
      t.boolean :activa, null: false, default: true

      t.timestamps
    end

    add_index :categorias, :nombre, unique: true
  end
end
