class CreateConsultasIa < ActiveRecord::Migration[8.1]
  def change
    create_table :consultas_ia do |t|
      t.references :usuario, null: true, foreign_key: true
      t.string :tipo, null: false, default: "chatbot"
      t.text :pregunta, null: false
      t.text :respuesta, null: false
      t.jsonb :contexto, null: false, default: {}

      t.timestamps
    end

    add_index :consultas_ia, :tipo
    add_index :consultas_ia, :created_at
  end
end
