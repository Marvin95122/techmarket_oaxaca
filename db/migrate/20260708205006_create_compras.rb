class CreateCompras < ActiveRecord::Migration[8.1]
  def change
    create_table :compras do |t|
      t.references :usuario, null: false, foreign_key: true
      t.decimal :total, precision: 10, scale: 2, null: false, default: 0
      t.string :estado, null: false, default: "pagada"

      t.timestamps
    end
  end
end
