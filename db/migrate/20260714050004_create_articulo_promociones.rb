class CreateArticuloPromociones < ActiveRecord::Migration[8.1]
  def change
    create_table :articulo_promociones do |t|
      t.references :articulo,
                   null: false,
                   foreign_key: true

      t.references :promocion,
                   null: false,
                   foreign_key: { to_table: :promociones }

      t.timestamps
    end

    add_index :articulo_promociones,
              [:articulo_id, :promocion_id],
              unique: true,
              name: "index_articulo_promociones_unico"
  end
end