class CreatePromociones < ActiveRecord::Migration[8.1]
  def change
    create_table :promociones do |t|
      t.string :nombre, null: false
      t.text :descripcion
      t.string :tipo_descuento, null: false
      t.decimal :valor, precision: 10, scale: 2, null: false
      t.datetime :fecha_inicio, null: false
      t.datetime :fecha_fin, null: false
      t.boolean :activa, null: false, default: true
      t.string :codigo

      t.timestamps
    end

    add_index :promociones, :codigo, unique: true
    add_index :promociones, [:activa, :fecha_inicio, :fecha_fin], name: "index_promociones_vigencia"
  end
end
