class CreateMarcasAndAddToArticulos < ActiveRecord::Migration[8.1]
  def up
    create_table :marcas do |t|
      t.string :nombre, null: false
      t.text :descripcion
      t.boolean :activa, null: false, default: true

      t.timestamps
    end

    add_index :marcas, :nombre, unique: true

    add_reference :articulos,
                  :marca,
                  null: true,
                  foreign_key: { to_table: :marcas }

    execute <<~SQL
      INSERT INTO marcas (nombre, descripcion, activa, created_at, updated_at)
      VALUES (
        'Sin marca',
        'Marca temporal asignada a los artículos existentes.',
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      )
      ON CONFLICT (nombre) DO NOTHING;
    SQL

    execute <<~SQL
      UPDATE articulos
      SET marca_id = marcas.id
      FROM marcas
      WHERE marcas.nombre = 'Sin marca'
        AND articulos.marca_id IS NULL;
    SQL

    change_column_null :articulos, :marca_id, false
  end

  def down
    remove_reference :articulos,
                     :marca,
                     foreign_key: { to_table: :marcas }

    drop_table :marcas
  end
end
