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

ActiveRecord::Schema[8.1].define(version: 2026_07_07_205229) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "articulos", force: :cascade do |t|
    t.string "categoria", null: false
    t.datetime "created_at", null: false
    t.text "descripcion", null: false
    t.string "imagen_url"
    t.string "nombre", null: false
    t.decimal "precio", precision: 10, scale: 2, null: false
    t.integer "stock", default: 0, null: false
    t.datetime "updated_at", null: false
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
end
