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

ActiveRecord::Schema.define(version: 2021_08_13_132203) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "arch_objects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "material_id"
    t.integer "species_id"
    t.integer "on_site_object_position_id"
    t.integer "site_phase_id"
  end

  create_table "c14_measurements", force: :cascade do |t|
    t.integer "bp"
    t.integer "std"
    t.integer "cal_bp"
    t.integer "cal_std"
    t.float "delta_c13"
    t.float "delta_c13_std"
    t.string "method"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "source_database_id"
    t.index ["source_database_id"], name: "index_c14_measurements_on_source_database_id"
  end

  create_table "countries", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ecochronological_units", force: :cascade do |t|
    t.string "name"
    t.integer "approx_start_time"
    t.integer "approx_end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "parent_id"
  end

  create_table "ecochronological_units_site_phases", id: false, force: :cascade do |t|
    t.bigint "site_phase_id", null: false
    t.bigint "ecochronological_unit_id", null: false
    t.index ["site_phase_id", "ecochronological_unit_id"], name: "index_speu"
  end

  create_table "feature_types", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fell_phases", force: :cascade do |t|
    t.string "name"
    t.integer "start_time"
    t.integer "end_time"
    t.integer "site_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id"], name: "index_fell_phases_on_site_id"
  end

  create_table "fell_phases_references", id: false, force: :cascade do |t|
    t.bigint "fell_phase_id", null: false
    t.bigint "reference_id", null: false
    t.index ["fell_phase_id", "reference_id"], name: "index_fpr"
  end

  create_table "labs", force: :cascade do |t|
    t.string "name"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "materials", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "measurements", force: :cascade do |t|
    t.string "labnr"
    t.integer "sample_id"
    t.integer "lab_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "c14_measurement_id"
    t.index ["c14_measurement_id"], name: "index_measurements_on_c14_measurement_id"
    t.index ["lab_id"], name: "index_measurements_on_lab_id"
    t.index ["sample_id"], name: "index_measurements_on_sample_id"
  end

  create_table "measurements_references", id: false, force: :cascade do |t|
    t.bigint "measurement_id", null: false
    t.integer "reference_id", null: false
    t.index ["measurement_id", "reference_id"], name: "index_mr"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.bigint "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.bigint "resource_owner_id"
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "on_site_object_positions", force: :cascade do |t|
    t.string "feature"
    t.string "site_grid_square"
    t.string "coord_reference_system"
    t.decimal "coord_X"
    t.decimal "coord_Y"
    t.decimal "coord_Z"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "feature_type_id"
  end

  create_table "periods", force: :cascade do |t|
    t.string "name"
    t.integer "approx_start_time"
    t.integer "approx_end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "parent_id"
  end

  create_table "periods_site_phases", id: false, force: :cascade do |t|
    t.bigint "site_phase_id", null: false
    t.bigint "period_id", null: false
    t.index ["site_phase_id", "period_id"], name: "index_spp"
  end

  create_table "physical_locations", force: :cascade do |t|
    t.bigint "site_id"
    t.bigint "country_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_physical_locations_on_country_id"
    t.index ["site_id"], name: "index_physical_locations_on_site_id"
  end

  create_table "references", force: :cascade do |t|
    t.text "bibtex"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "short_ref"
  end

  create_table "samples", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "arch_object_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "site_phases", force: :cascade do |t|
    t.string "name"
    t.integer "approx_start_time"
    t.integer "approx_end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "site_id"
    t.integer "site_type_id"
  end

  create_table "site_phases_typochronological_units", id: false, force: :cascade do |t|
    t.bigint "site_phase_id", null: false
    t.bigint "typochronological_unit_id", null: false
    t.index ["site_phase_id", "typochronological_unit_id"], name: "index_sptu"
  end

  create_table "site_types", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sites", force: :cascade do |t|
    t.string "name"
    t.decimal "lat"
    t.decimal "lng"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "country_id"
  end

  create_table "source_databases", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.text "citation"
    t.string "licence"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "species", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "typochronological_units", force: :cascade do |t|
    t.string "name"
    t.integer "approx_start_time"
    t.integer "approx_end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "parent_id"
  end

  create_table "user_profiles", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_user_profiles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.text "object_changes"
    t.string "whodunnit_user_email"
    t.text "revision_comment"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "c14_measurements", "source_databases"
  add_foreign_key "measurements", "c14_measurements"
  add_foreign_key "measurements", "labs"
  add_foreign_key "measurements", "samples"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_grants", "users", column: "resource_owner_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "users", column: "resource_owner_id"
  add_foreign_key "user_profiles", "users"
end
