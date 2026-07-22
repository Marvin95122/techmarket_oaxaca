class AddShippingTrackingToCompras < ActiveRecord::Migration[8.1]
  def up
    add_column :compras, :estado_envio, :string, default: "pendiente", null: false
    add_column :compras, :cancelada_por, :string
    add_column :compras, :en_transito_en, :datetime
    add_column :compras, :entregada_en, :datetime

    add_index :compras, :estado_envio
    add_index :compras, :cancelada_por
    add_index :compras, :en_transito_en
    add_index :compras, :entregada_en

    execute <<~SQL.squish
      UPDATE compras
      SET estado_envio = 'cancelado'
      WHERE estado = 'cancelada'
    SQL
  end

  def down
    remove_index :compras, :entregada_en
    remove_index :compras, :en_transito_en
    remove_index :compras, :cancelada_por
    remove_index :compras, :estado_envio

    remove_column :compras, :entregada_en
    remove_column :compras, :en_transito_en
    remove_column :compras, :cancelada_por
    remove_column :compras, :estado_envio
  end
end
