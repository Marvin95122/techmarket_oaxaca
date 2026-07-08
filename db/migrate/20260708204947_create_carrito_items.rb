class CreateCarritoItems < ActiveRecord::Migration[8.1]
  def change
    create_table :carrito_items do |t|
      t.references :usuario, null: false, foreign_key: true
      t.references :articulo, null: false, foreign_key: true
      t.integer :cantidad, null: false, default: 1

      t.timestamps
    end

    add_index :carrito_items, [:usuario_id, :articulo_id], unique: true
  end
end
