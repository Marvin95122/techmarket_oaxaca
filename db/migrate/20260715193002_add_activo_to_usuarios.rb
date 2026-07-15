class AddActivoToUsuarios < ActiveRecord::Migration[8.1]
  def change
    add_column :usuarios, :activo, :boolean, null: false, default: true
    add_index :usuarios, :activo
  end
end
