# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_14_050005) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "articulo_promociones", force: :cascade do |t|
    t.bigint "articulo_id", null: false
    t.datetime "created_at", null: false
    t.bigint "promocion_id", null: false
    t.datetime "updated_at", null: false
    t.index ["articulo_id", "promocion_id"], name: "index_articulo_promociones_unico", unique: true
    t.index ["articulo_id"], name: "index_articulo_promociones_on_articulo_id"
    t.index ["promocion_id"], name: "index_articulo_promociones_on_promocion_id"
  end

  create_table "articulos", force: :cascade do |t|
    t.bigint "categoria_id", null: false
    t.datetime "created_at", null: false
    t.text "descripcion", null: false
    t.string "imagen_url"
    t.string "nombre", null: false
    t.decimal "precio", precision: 10, scale: 2, null: false
    t.integer "stock", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["categoria_id"], name: "index_articulos_on_categoria_id"
  end

  create_table "carrito_items", force: :cascade do |t|
    t.bigint "articulo_id", null: false
    t.integer "cantidad", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "usuario_id", null: false
    t.index ["articulo_id"], name: "index_carrito_items_on_articulo_id"
    t.index ["usuario_id", "articulo_id"], name: "index_carrito_items_on_usuario_id_and_articulo_id", unique: true
    t.index ["usuario_id"], name: "index_carrito_items_on_usuario_id"
  end

  create_table "categorias", force: :cascade do |t|
    t.boolean "activa", default: true, null: false
    t.datetime "created_at", null: false
    t.text "descripcion"
    t.string "nombre", null: false
    t.datetime "updated_at", null: false
    t.index ["nombre"], name: "index_categorias_on_nombre", unique: true
  end

  create_table "compra_items", force: :cascade do |t|
    t.bigint "articulo_id", null: false
    t.integer "cantidad", null: false
    t.bigint "compra_id", null: false
    t.datetime "created_at", null: false
    t.decimal "precio_unitario", precision: 10, scale: 2, null: false
    t.decimal "subtotal", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["articulo_id"], name: "index_compra_items_on_articulo_id"
    t.index ["compra_id"], name: "index_compra_items_on_compra_id"
  end

  create_table "compras", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "estado", default: "pagada", null: false
    t.decimal "total", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.bigint "usuario_id", null: false
    t.index ["usuario_id"], name: "index_compras_on_usuario_id"
  end

  create_table "consultas_ia", force: :cascade do |t|
    t.jsonb "contexto", default: {}, null: false
    t.datetime "created_at", null: false
    t.text "pregunta", null: false
    t.text "respuesta", null: false
    t.string "tipo", default: "chatbot", null: false
    t.datetime "updated_at", null: false
    t.bigint "usuario_id"
    t.index ["created_at"], name: "index_consultas_ia_on_created_at"
    t.index ["tipo"], name: "index_consultas_ia_on_tipo"
    t.index ["usuario_id"], name: "index_consultas_ia_on_usuario_id"
  end

  create_table "promociones", force: :cascade do |t|
    t.boolean "activa", default: true, null: false
    t.string "codigo"
    t.datetime "created_at", null: false
    t.text "descripcion"
    t.datetime "fecha_fin", null: false
    t.datetime "fecha_inicio", null: false
    t.string "nombre", null: false
    t.string "tipo_descuento", null: false
    t.datetime "updated_at", null: false
    t.decimal "valor", precision: 10, scale: 2, null: false
    t.index ["activa", "fecha_inicio", "fecha_fin"], name: "index_promociones_vigencia"
    t.index ["codigo"], name: "index_promociones_on_codigo", unique: true
  end

  create_table "resenas", force: :cascade do |t|
    t.bigint "articulo_id", null: false
    t.integer "calificacion", null: false
    t.text "comentario", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "usuario_id", null: false
    t.index ["articulo_id"], name: "index_resenas_on_articulo_id"
    t.index ["usuario_id", "articulo_id"], name: "index_resenas_on_usuario_id_and_articulo_id", unique: true
    t.index ["usuario_id"], name: "index_resenas_on_usuario_id"
  end

  create_table "usuarios", force: :cascade do |t|
    t.string "correo", null: false
    t.datetime "created_at", null: false
    t.string "nombre", null: false
    t.string "password_digest", null: false
    t.string "rol", default: "usuario", null: false
    t.datetime "updated_at", null: false
    t.index ["correo"], name: "index_usuarios_on_correo", unique: true
  end

  add_foreign_key "articulo_promociones", "articulos"
  add_foreign_key "articulo_promociones", "promociones", column: "promocion_id"
  add_foreign_key "articulos", "categorias"
  add_foreign_key "carrito_items", "articulos"
  add_foreign_key "carrito_items", "usuarios"
  add_foreign_key "compra_items", "articulos"
  add_foreign_key "compra_items", "compras"
  add_foreign_key "compras", "usuarios"
  add_foreign_key "consultas_ia", "usuarios"
  add_foreign_key "resenas", "articulos"
  add_foreign_key "resenas", "usuarios"
end
