class AddCancelacionToCompras < ActiveRecord::Migration[8.1]
  def change
    add_column :compras, :cancelada_en, :datetime
    add_column :compras, :motivo_cancelacion, :text
    add_index :compras, :estado
    add_index :compras, :cancelada_en
  end
end
