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

ActiveRecord::Schema[8.0].define(version: 2025_08_12_153010) do
  create_table "fighter_feature_categories", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_fighter_feature_categories_on_name", unique: true
  end

  create_table "fighter_features", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "fighter_id", null: false
    t.string "feature", null: false
    t.integer "level", null: false
    t.bigint "fighter_feature_category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fighter_feature_category_id"], name: "index_fighter_features_on_fighter_feature_category_id"
    t.index ["fighter_id", "level"], name: "index_fighter_features_on_fighter_id_and_level"
    t.index ["fighter_id"], name: "index_fighter_features_on_fighter_id"
    t.check_constraint "`level` between 1 and 3", name: "level_range"
  end

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
    t.string "full_name_english"
    t.string "image_url"
    t.index ["full_name"], name: "index_fighters_on_full_name", unique: true
    t.index ["full_name_hiragana"], name: "index_fighters_on_full_name_hiragana", unique: true
    t.index ["is_active"], name: "index_fighters_on_is_active"
  end

  create_table "game_players", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "game_session_id", null: false
    t.bigint "user_id", null: false
    t.integer "turn_order", null: false
    t.boolean "is_eliminated", default: false, null: false
    t.datetime "joined_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_session_id", "turn_order"], name: "index_game_players_on_game_session_id_and_turn_order", unique: true
    t.index ["game_session_id", "user_id"], name: "index_game_players_on_game_session_id_and_user_id", unique: true
    t.index ["game_session_id"], name: "index_game_players_on_game_session_id"
    t.index ["user_id"], name: "index_game_players_on_user_id"
  end

  create_table "game_sessions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.integer "status", default: 0, null: false
    t.bigint "creator_id", null: false
    t.bigint "current_turn_player_id"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "winner_user_id"
    t.index ["creator_id"], name: "index_game_sessions_on_creator_id"
    t.index ["current_turn_player_id"], name: "fk_rails_8320569b62"
    t.index ["status"], name: "index_game_sessions_on_status"
    t.index ["winner_user_id"], name: "index_game_sessions_on_winner_user_id"
  end

  create_table "quiz_answers", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "quiz_session_id", null: false
    t.bigint "user_id", null: false
    t.bigint "fighter_id"
    t.boolean "is_correct", null: false
    t.datetime "submitted_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "hint_index"
    t.bigint "fighter_feature_id", null: false
    t.index ["fighter_feature_id"], name: "index_quiz_answers_on_fighter_feature_id"
    t.index ["fighter_id"], name: "index_quiz_answers_on_fighter_id"
    t.index ["quiz_session_id", "user_id", "fighter_feature_id"], name: "index_quiz_answers_on_session_and_feature", unique: true
    t.index ["quiz_session_id", "user_id", "submitted_at"], name: "idx_on_quiz_session_id_user_id_submitted_at_c0a4fe3553"
    t.index ["quiz_session_id"], name: "index_quiz_answers_on_quiz_session_id"
    t.index ["user_id"], name: "index_quiz_answers_on_user_id"
  end

  create_table "quiz_hints", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "quiz_session_id", null: false
    t.bigint "fighter_feature_id", null: false
    t.integer "display_order", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fighter_feature_id"], name: "index_quiz_hints_on_fighter_feature_id"
    t.index ["quiz_session_id", "display_order"], name: "index_quiz_hints_on_quiz_session_id_and_display_order", unique: true
    t.index ["quiz_session_id", "fighter_feature_id"], name: "index_quiz_hints_on_quiz_session_id_and_fighter_feature_id", unique: true
    t.index ["quiz_session_id"], name: "index_quiz_hints_on_quiz_session_id"
  end

  create_table "quiz_participants", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "quiz_session_id", null: false
    t.bigint "user_id", null: false
    t.integer "miss_count", default: 0
    t.datetime "answered_at"
    t.integer "points", default: 0
    t.boolean "is_winner", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "responded_at"
    t.datetime "connected_at"
    t.index ["quiz_session_id", "user_id"], name: "index_quiz_participants_on_quiz_session_id_and_user_id", unique: true
    t.index ["quiz_session_id"], name: "index_quiz_participants_on_quiz_session_id"
    t.index ["user_id"], name: "index_quiz_participants_on_user_id"
  end

  create_table "quiz_sessions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "creator_id", null: false
    t.bigint "target_fighter_id", null: false
    t.string "status", default: "waiting", null: false
    t.integer "current_hint_index", default: 0
    t.datetime "started_at"
    t.datetime "ended_at"
    t.bigint "winner_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "solo_mode", default: false, null: false
    t.index ["creator_id"], name: "index_quiz_sessions_on_creator_id"
    t.index ["target_fighter_id"], name: "index_quiz_sessions_on_target_fighter_id"
    t.index ["winner_user_id"], name: "index_quiz_sessions_on_winner_user_id"
  end

  create_table "used_fighters", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "game_session_id", null: false
    t.bigint "fighter_id", null: false
    t.bigint "used_by_id", null: false
    t.datetime "used_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fighter_id"], name: "index_used_fighters_on_fighter_id"
    t.index ["game_session_id", "fighter_id"], name: "index_used_fighters_on_game_session_id_and_fighter_id", unique: true
    t.index ["game_session_id"], name: "index_used_fighters_on_game_session_id"
    t.index ["used_by_id"], name: "index_used_fighters_on_used_by_id"
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
    t.boolean "is_admin", default: false, null: false
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

  add_foreign_key "fighter_features", "fighter_feature_categories"
  add_foreign_key "fighter_features", "fighters"
  add_foreign_key "fighter_weight_classes", "fighters"
  add_foreign_key "fighter_weight_classes", "weight_classes"
  add_foreign_key "game_players", "game_sessions"
  add_foreign_key "game_players", "users"
  add_foreign_key "game_sessions", "users", column: "creator_id"
  add_foreign_key "game_sessions", "users", column: "current_turn_player_id"
  add_foreign_key "game_sessions", "users", column: "winner_user_id"
  add_foreign_key "quiz_answers", "fighter_features"
  add_foreign_key "quiz_answers", "fighters"
  add_foreign_key "quiz_answers", "quiz_sessions"
  add_foreign_key "quiz_answers", "users"
  add_foreign_key "quiz_hints", "fighter_features"
  add_foreign_key "quiz_hints", "quiz_sessions"
  add_foreign_key "quiz_participants", "quiz_sessions"
  add_foreign_key "quiz_participants", "users"
  add_foreign_key "quiz_sessions", "fighters", column: "target_fighter_id"
  add_foreign_key "quiz_sessions", "users", column: "creator_id"
  add_foreign_key "quiz_sessions", "users", column: "winner_user_id"
  add_foreign_key "used_fighters", "fighters"
  add_foreign_key "used_fighters", "game_sessions"
  add_foreign_key "used_fighters", "users", column: "used_by_id"
end
