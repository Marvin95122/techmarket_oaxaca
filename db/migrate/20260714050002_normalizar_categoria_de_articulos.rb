class NormalizarCategoriaDeArticulos < ActiveRecord::Migration[8.1]
  def up
    add_reference :articulos,
                  :categoria,
                  null: true,
                  foreign_key: { to_table: :categorias }

    execute <<~SQL
      INSERT INTO categorias (
        nombre,
        descripcion,
        activa,
        created_at,
        updated_at
      )
      SELECT DISTINCT
             categoria,
             'Categoría migrada automáticamente desde artículos.',
             TRUE,
             CURRENT_TIMESTAMP,
             CURRENT_TIMESTAMP
      FROM articulos
      WHERE categoria IS NOT NULL
        AND BTRIM(categoria) <> ''
      ON CONFLICT (nombre) DO NOTHING;
    SQL

    execute <<~SQL
      UPDATE articulos
      SET categoria_id = categorias.id
      FROM categorias
      WHERE categorias.nombre = articulos.categoria;
    SQL

    change_column_null :articulos, :categoria_id, false

    remove_column :articulos, :categoria, :string
  end

  def down
    add_column :articulos, :categoria, :string

    execute <<~SQL
      UPDATE articulos
      SET categoria = categorias.nombre
      FROM categorias
      WHERE categorias.id = articulos.categoria_id;
    SQL

    change_column_null :articulos, :categoria, false

    remove_reference :articulos,
                     :categoria,
                     foreign_key: { to_table: :categorias }
  end
end