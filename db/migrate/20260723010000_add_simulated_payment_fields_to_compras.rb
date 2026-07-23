class AddSimulatedPaymentFieldsToCompras < ActiveRecord::Migration[8.1]
  def up
    add_column :compras, :metodo_pago, :string
    add_column :compras, :referencia_pago, :string
    add_column :compras, :codigo_barras, :string
    add_column :compras, :pago_confirmado_en, :datetime
    add_column :compras, :pago_expira_en, :datetime
    add_column :compras, :tarjeta_ultimos4, :string
    add_column :compras, :tarjeta_marca, :string
    add_column :compras, :autorizacion_pago, :string

    # Las compras históricas pagadas o canceladas se consideran pagos con
    # tarjeta simulada para mantener compatibilidad con las fases anteriores.
    execute <<~SQL.squish
      UPDATE compras
      SET metodo_pago = 'tarjeta',
          pago_confirmado_en = COALESCE(cancelada_en, created_at),
          tarjeta_ultimos4 = '0000',
          tarjeta_marca = 'Histórica',
          autorizacion_pago = 'LEGACY-' || id::text
      WHERE estado IN ('pagada', 'cancelada')
    SQL

    # Si existiera alguna compra histórica pendiente, se conserva como OXXO.
    execute <<~SQL.squish
      UPDATE compras
      SET metodo_pago = 'oxxo',
          referencia_pago = 'HIST' || LPAD(id::text, 10, '0'),
          codigo_barras = LPAD(id::text, 18, '0'),
          pago_expira_en = created_at + INTERVAL '3 days'
      WHERE estado = 'pendiente'
    SQL

    change_column_null :compras, :metodo_pago, false
    change_column_default :compras, :metodo_pago, from: nil, to: 'tarjeta'
    change_column_default :compras, :estado, from: 'pagada', to: 'pendiente'

    add_index :compras, :metodo_pago
    add_index :compras, :referencia_pago, unique: true
    add_index :compras, :codigo_barras, unique: true
    add_index :compras, :pago_confirmado_en
    add_index :compras, :pago_expira_en
    add_index :compras, :autorizacion_pago
  end

  def down
    remove_index :compras, :autorizacion_pago
    remove_index :compras, :pago_expira_en
    remove_index :compras, :pago_confirmado_en
    remove_index :compras, :codigo_barras
    remove_index :compras, :referencia_pago
    remove_index :compras, :metodo_pago

    change_column_default :compras, :estado, from: 'pendiente', to: 'pagada'

    remove_column :compras, :autorizacion_pago
    remove_column :compras, :tarjeta_marca
    remove_column :compras, :tarjeta_ultimos4
    remove_column :compras, :pago_expira_en
    remove_column :compras, :pago_confirmado_en
    remove_column :compras, :codigo_barras
    remove_column :compras, :referencia_pago
    remove_column :compras, :metodo_pago
  end
end
