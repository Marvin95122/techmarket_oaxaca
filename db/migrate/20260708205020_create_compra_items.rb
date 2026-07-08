class CreateCompraItems < ActiveRecord::Migration[8.1]
  def change
    create_table :compra_items do |t|
      t.references :compra, null: false, foreign_key: true
      t.references :articulo, null: false, foreign_key: true
      t.integer :cantidad, null: false
      t.decimal :precio_unitario, precision: 10, scale: 2, null: false
      t.decimal :subtotal, precision: 10, scale: 2, null: false

      t.timestamps
    end
  end
end
