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

ActiveRecord::Schema[8.0].define(version: 2025_03_01_173000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "artists", force: :cascade do |t|
    t.string "name", null: false
    t.string "genre", null: false
    t.integer "energy", null: false
    t.integer "talent", null: false
    t.integer "skill", default: 0, null: false
    t.integer "popularity", default: 0, null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "traits", default: {}, null: false
    t.text "background"
    t.string "current_action"
    t.datetime "action_started_at"
    t.datetime "action_ends_at"
    t.string "nano_id"
    t.bigint "manager_id"
    t.decimal "cost", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "signing_cost", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "revenue", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "required_level", default: 1, null: false
    t.index ["cost"], name: "index_artists_on_cost"
    t.index ["manager_id"], name: "index_artists_on_manager_id"
    t.index ["name"], name: "index_artists_on_name"
    t.index ["nano_id"], name: "index_artists_on_nano_id", unique: true
    t.index ["popularity"], name: "index_artists_on_popularity"
    t.index ["required_level"], name: "index_artists_on_required_level"
    t.index ["revenue"], name: "index_artists_on_revenue"
    t.index ["signing_cost"], name: "index_artists_on_signing_cost"
    t.index ["traits"], name: "index_artists_on_traits", using: :gin
    t.index ["user_id"], name: "index_artists_on_user_id"
  end

  create_table "managers", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "budget", precision: 10, scale: 2, default: "1000.0", null: false
    t.integer "level", default: 1, null: false
    t.integer "xp", default: 0, null: false
    t.integer "skill_points", default: 0, null: false
    t.jsonb "traits", default: {}, null: false
    t.string "nano_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["budget"], name: "index_managers_on_budget"
    t.index ["level"], name: "index_managers_on_level"
    t.index ["nano_id"], name: "index_managers_on_nano_id", unique: true
    t.index ["user_id"], name: "index_managers_on_user_id"
  end

  create_table "scheduled_actions", force: :cascade do |t|
    t.string "activity_type"
    t.datetime "start_at"
    t.bigint "artist_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "nano_id"
    t.index ["artist_id"], name: "index_scheduled_actions_on_artist_id"
    t.index ["nano_id"], name: "index_scheduled_actions_on_nano_id", unique: true
  end

  create_table "seasons", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "active", default: false, null: false
    t.datetime "transition_ends_at"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.jsonb "genre_trends", default: {}, null: false
    t.jsonb "settings", default: {}, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "nano_id"
    t.index ["active"], name: "index_seasons_on_active"
    t.index ["nano_id"], name: "index_seasons_on_nano_id", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "nano_id"
    t.index ["nano_id"], name: "index_sessions_on_nano_id", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "manager_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "description", null: false
    t.string "transaction_type", null: false
    t.bigint "artist_id"
    t.string "nano_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["artist_id"], name: "index_transactions_on_artist_id"
    t.index ["created_at"], name: "index_transactions_on_created_at"
    t.index ["manager_id"], name: "index_transactions_on_manager_id"
    t.index ["nano_id"], name: "index_transactions_on_nano_id", unique: true
    t.index ["transaction_type"], name: "index_transactions_on_transaction_type"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false, null: false
    t.string "nano_id"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["nano_id"], name: "index_users_on_nano_id", unique: true
  end

  add_foreign_key "artists", "managers"
  add_foreign_key "artists", "users"
  add_foreign_key "managers", "users"
  add_foreign_key "scheduled_actions", "artists"
  add_foreign_key "sessions", "users"
  add_foreign_key "transactions", "artists"
  add_foreign_key "transactions", "managers"
end
