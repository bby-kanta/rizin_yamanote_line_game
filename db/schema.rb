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

ActiveRecord::Schema[8.0].define(version: 2025_08_09_161751) do
  create_table "fighter_weight_classes", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "fighter_id", null: false
    t.bigint "weight_class_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fighter_id", "weight_class_id"], name: "index_fighter_weight_classes_on_fighter_and_weight_class", unique: true
    t.index ["fighter_id"], name: "index_fighter_weight_classes_on_fighter_id"
    t.index ["weight_class_id"], name: "index_fighter_weight_classes_on_weight_class_id"
  end

  create_table "fighters", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "full_name", null: false
    t.string "full_name_hiragana", null: false
    t.string "ring_name"
    t.string "ring_name_hiragana"
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["full_name"], name: "index_fighters_on_full_name", unique: true
    t.index ["full_name_hiragana"], name: "index_fighters_on_full_name_hiragana", unique: true
    t.index ["is_active"], name: "index_fighters_on_is_active"
    t.index ["ring_name"], name: "index_fighters_on_ring_name", unique: true
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "weight_classes", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "japanese_name", null: false
    t.string "english_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["english_name"], name: "index_weight_classes_on_english_name", unique: true
    t.index ["japanese_name"], name: "index_weight_classes_on_japanese_name", unique: true
  end

  add_foreign_key "fighter_weight_classes", "fighters"
  add_foreign_key "fighter_weight_classes", "weight_classes"
end
