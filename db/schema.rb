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

ActiveRecord::Schema[8.1].define(version: 2026_07_20_140254) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "partner_user_mappings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "partner_id", null: false
    t.string "partner_user_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["partner_id", "partner_user_id"], name: "index_partner_user_mappings_on_partner_id_and_partner_user_id", unique: true
    t.index ["partner_id"], name: "index_partner_user_mappings_on_partner_id"
    t.index ["user_id"], name: "index_partner_user_mappings_on_user_id"
  end

  create_table "partners", force: :cascade do |t|
    t.string "api_key_digest", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["api_key_digest"], name: "index_partners_on_api_key_digest", unique: true
  end

  create_table "rewards", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.decimal "points_required", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_rewards_on_name", unique: true
  end

  create_table "transactions", force: :cascade do |t|
    t.string "activity_type", null: false
    t.decimal "amount"
    t.datetime "created_at", null: false
    t.string "external_id", null: false
    t.string "kind", null: false
    t.bigint "partner_id", null: false
    t.decimal "points_delta", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["partner_id", "user_id", "external_id"], name: "index_transactions_on_partner_id_and_user_id_and_external_id", unique: true
    t.index ["partner_id"], name: "index_transactions_on_partner_id"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "partner_user_mappings", "partners"
  add_foreign_key "partner_user_mappings", "users"
  add_foreign_key "transactions", "partners"
  add_foreign_key "transactions", "users"
end
