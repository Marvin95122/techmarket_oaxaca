class CreateArticulos < ActiveRecord::Migration[8.1]
  def change
    create_table :articulos do |t|
      t.string :nombre, null: false
      t.text :descripcion, null: false
      t.decimal :precio, precision: 10, scale: 2, null: false
      t.integer :stock, null: false, default: 0
      t.string :categoria, null: false
      t.string :imagen_url

      t.timestamps
    end
  end
end