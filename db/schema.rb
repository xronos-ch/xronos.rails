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

ActiveRecord::Schema[7.0].define(version: 2023_12_08_103730) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"
  enable_extension "unaccent"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "articles", force: :cascade do |t|
    t.integer "section", null: false
    t.string "slug"
    t.string "title"
    t.bigint "user_id"
    t.datetime "published_at", precision: nil
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "splash_attribution"
    t.boolean "publish", default: false
    t.index ["section"], name: "index_articles_on_section"
    t.index ["slug"], name: "index_articles_on_slug", unique: true
    t.index ["user_id"], name: "index_articles_on_user_id"
  end

  create_table "c14_labs", force: :cascade do |t|
    t.string "name"
    t.boolean "active"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["active"], name: "index_c14_labs_on_active"
    t.index ["name"], name: "index_c14_labs_on_name"
  end

  create_table "c14s", force: :cascade do |t|
    t.integer "bp"
    t.integer "std"
    t.integer "cal_bp"
    t.integer "cal_std"
    t.float "delta_c13"
    t.float "delta_c13_std"
    t.string "method"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "c14_lab_id"
    t.bigint "sample_id"
    t.string "lab_identifier"
    t.index ["c14_lab_id"], name: "index_c14s_on_c14_lab_id"
    t.index ["lab_identifier"], name: "index_c14s_on_lab_identifier"
    t.index ["method"], name: "index_c14s_on_method"
    t.index ["sample_id"], name: "index_c14s_on_sample_id"
  end

  create_table "citations", force: :cascade do |t|
    t.bigint "reference_id"
    t.string "citing_type"
    t.bigint "citing_id"
    t.index ["citing_type", "citing_id"], name: "index_citations_on_citing"
    t.index ["reference_id"], name: "index_citations_on_reference_id"
  end

  create_table "contexts", force: :cascade do |t|
    t.string "name"
    t.integer "approx_start_time"
    t.integer "approx_end_time"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "site_id"
    t.index ["name"], name: "index_contexts_on_name"
    t.index ["site_id"], name: "index_contexts_on_site_id"
  end

  create_table "import_tables", force: :cascade do |t|
    t.string "file"
    t.datetime "imported_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.jsonb "read_options"
    t.jsonb "mapping"
    t.index ["user_id"], name: "index_import_tables_on_user_id"
  end

  create_table "materials", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["name"], name: "index_materials_on_name"
  end

  create_table "measurement_states", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_measurement_states_on_name"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.bigint "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "revoked_at", precision: nil
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
    t.datetime "revoked_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "periods_site_phases", id: false, force: :cascade do |t|
    t.bigint "site_phase_id", null: false
    t.bigint "period_id", null: false
    t.index ["site_phase_id", "period_id"], name: "index_spp"
  end

  create_table "pg_search_documents", force: :cascade do |t|
    t.text "content"
    t.string "searchable_type"
    t.bigint "searchable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable"
  end

  create_table "physical_locations", force: :cascade do |t|
    t.bigint "site_id"
    t.bigint "country_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["country_id"], name: "index_physical_locations_on_country_id"
    t.index ["site_id"], name: "index_physical_locations_on_site_id"
  end

  create_table "references", force: :cascade do |t|
    t.text "bibtex"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "short_ref"
    t.index ["short_ref"], name: "index_references_on_short_ref"
  end

  create_table "samples", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "material_id"
    t.integer "taxon_id"
    t.integer "context_id"
    t.text "position_description"
    t.decimal "position_x"
    t.decimal "position_y"
    t.decimal "position_z"
    t.text "position_crs"
    t.index ["context_id"], name: "index_samples_on_context_id"
    t.index ["material_id"], name: "index_samples_on_material_id"
    t.index ["position_crs"], name: "index_samples_on_position_crs"
    t.index ["taxon_id"], name: "index_samples_on_taxon_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "site_names", force: :cascade do |t|
    t.string "language"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "site_id"
    t.index ["site_id"], name: "index_site_names_on_site_id"
  end

  create_table "site_types", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["name"], name: "index_site_types_on_name"
  end

  create_table "site_types_sites", id: false, force: :cascade do |t|
    t.bigint "site_id"
    t.bigint "site_type_id"
    t.index ["site_id"], name: "index_site_types_sites_on_site_id"
    t.index ["site_type_id"], name: "index_site_types_sites_on_site_type_id"
  end

  create_table "sites", force: :cascade do |t|
    t.string "name"
    t.decimal "lat"
    t.decimal "lng"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "country_code"
    t.integer "superseded_by"
    t.index ["country_code"], name: "index_sites_on_country_code"
    t.index ["name"], name: "index_sites_on_name"
  end

  create_table "taxons", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "gbif_id"
    t.index ["gbif_id"], name: "index_taxons_on_gbif_id"
    t.index ["name"], name: "index_taxons_on_name"
  end

  create_table "typos", force: :cascade do |t|
    t.string "name"
    t.integer "approx_start_time"
    t.integer "approx_end_time"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "parent_id"
    t.bigint "sample_id"
    t.index ["name"], name: "index_typos_on_name"
    t.index ["sample_id"], name: "index_typos_on_sample_id"
  end

  create_table "user_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "full_name"
    t.string "orcid"
    t.string "public_email"
    t.string "url"
    t.index ["user_id"], name: "index_user_profiles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "admin", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type"
    t.string "{:null=>false}"
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at", precision: nil
    t.string "whodunnit_user_email"
    t.text "revision_comment"
    t.jsonb "new_object"
    t.jsonb "object_changes"
    t.index ["event"], name: "index_versions_on_event"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    t.index ["whodunnit"], name: "index_versions_on_whodunnit"
  end

  create_table "wikidata_links", force: :cascade do |t|
    t.integer "qid"
    t.string "wikidata_linkable_type"
    t.bigint "wikidata_linkable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["qid"], name: "index_wikidata_links_on_qid"
    t.index ["wikidata_linkable_type", "wikidata_linkable_id"], name: "index_wikidata_links_on_linkable_type_and_linkable_id"
    t.index ["wikidata_linkable_type", "wikidata_linkable_id"], name: "index_wikidata_links_on_wikidata_linkable"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "import_tables", "users"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_grants", "users", column: "resource_owner_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "users", column: "resource_owner_id"
  add_foreign_key "site_names", "sites"
  add_foreign_key "user_profiles", "users"
end
