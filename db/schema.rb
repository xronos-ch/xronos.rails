# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_06_18_074009) do

  create_table "arch_objects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "site_id"
    t.integer "material_id"
  end

  create_table "c14_measurements", force: :cascade do |t|
    t.integer "bp"
    t.integer "std"
    t.decimal "delta_c13"
    t.decimal "delta_c13_std"
    t.string "method"
  end

  create_table "countries", force: :cascade do |t|
    t.string "name"
    t.string "abbreviation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cultures", force: :cascade do |t|
    t.string "name"
    t.integer "approx_start_ime"
    t.integer "approx_end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "dendro_measurements", force: :cascade do |t|
    t.integer "age"
    t.integer "start_age_deviation"
    t.integer "end_age_deviation"
    t.string "dating_quality_estimation_category"
  end

  create_table "feature_types", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.integer "year"
    t.string "labnr"
    t.integer "sample_id"
    t.integer "lab_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "actable_id"
    t.string "actable_type"
    t.index ["lab_id"], name: "index_measurements_on_lab_id"
    t.index ["sample_id"], name: "index_measurements_on_sample_id"
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
  end

  create_table "phases", force: :cascade do |t|
    t.string "name"
    t.integer "approx_start_ime"
    t.integer "approx_end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "physical_locations", force: :cascade do |t|
    t.integer "site_id"
    t.integer "country_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_physical_locations_on_country_id"
    t.index ["site_id"], name: "index_physical_locations_on_site_id"
  end

  create_table "references", force: :cascade do |t|
    t.text "bibtex"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "samples", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "arch_object_id"
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
  end

  create_table "species", force: :cascade do |t|
    t.string "family"
    t.string "genus"
    t.string "species"
    t.string "subspecies"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
