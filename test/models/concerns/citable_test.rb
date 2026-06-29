require "test_helper"

class CitableTest < ActiveSupport::TestCase
  setup do
    ActiveRecord::Schema.define do
      suppress_messages do
        create_table :citable_models, force: true do |t|
          t.string :name
          t.timestamps
        end
      end
    end
  end

  class CitableModel < ApplicationRecord
    self.table_name = "citable_models"

    include Versioned
    include Citable

    def self.label
      "test record"
    end

    def polymorphic_url(*)
      "http://example.com/citable_models/#{id}"
    end
  end

  test "citation returns a Hash" do
    PaperTrail.request(whodunnit: 1) do
      record = CitableModel.create!(name: "Test")
      assert_kind_of Hash, record.citation
    end
  end

  test "citation type is entry with a model-prefixed id" do
    PaperTrail.request(whodunnit: 1) do
      record = CitableModel.create!(name: "Test")
      assert_equal "entry", record.citation['type']
      assert_equal "xronos_citable_test_citable_model_#{record.id}", record.citation['id']
    end
  end

  test "citation year is the current year" do
    PaperTrail.request(whodunnit: 1) do
      record = CitableModel.create!(name: "Test")
      assert_equal Time.current.year, record.citation['issued']['date-parts'].flatten.first
    end
  end

  test "citation title defaults to model name and id" do
    PaperTrail.request(whodunnit: 1) do
      record = CitableModel.create!(name: "Test")
      assert_equal "XRONOS citable_test_citable_model ##{record.id} (test record)", record.citation['title']
    end
  end

  test "citation URL is the polymorphic URL" do
    PaperTrail.request(whodunnit: 1) do
      record = CitableModel.create!(name: "Test")
      assert_equal "http://example.com/citable_models/#{record.id}", record.citation['URL']
    end
  end

  test "citation container-title is the XRONOS project name" do
    PaperTrail.request(whodunnit: 1) do
      record = CitableModel.create!(name: "Test")
      assert_equal "XRONOS: An Open Data Infrastructure for Archaeological Chronology",
        record.citation['container-title']
    end
  end

  test "citation accessed is the current time" do
    freeze_time = Time.zone.local(2026, 6, 29, 12, 0, 0)
    travel_to(freeze_time) do
      PaperTrail.request(whodunnit: 1) do
        record = CitableModel.create!(name: "Test")
        assert_equal [freeze_time.year, freeze_time.month, freeze_time.day],
          record.citation['accessed']['date-parts'].first
      end
    end
  end

  test "render_citation returns an html-safe string containing the URL" do
    PaperTrail.request(whodunnit: 1) do
      record = CitableModel.create!(name: "Test")
      rendered = record.render_citation
      assert_predicate rendered, :html_safe?
      assert_includes rendered, "http://example.com"
    end
  end

  test "citation author is the single named contributor" do
    user = create(:user)
    user.user_profile.update!(full_name: "Alice Smith")

    PaperTrail.request(whodunnit: user.id) do
      record = CitableModel.create!(name: "Test")
      assert_equal [{ "family" => "Smith", "given" => "Alice" }], record.citation['author']
    end
  end

  test "contributors without a real name are excluded" do
    user = create(:user)
    user.user_profile.update!(full_name: nil)

    PaperTrail.request(whodunnit: user.id) do
      record = CitableModel.create!(name: "Test")
      assert_equal [{ "literal" => "XRONOS contributors" }], record.citation['author']
    end
  end

  test "creator is the first author, others are sorted alphabetically" do
    zara = create(:user)
    zara.user_profile.update!(full_name: "Zara Zebra")
    alice = create(:user)
    alice.user_profile.update!(full_name: "Alice Smith")
    bob = create(:user)
    bob.user_profile.update!(full_name: "Bob Brown")

    PaperTrail.request(whodunnit: zara.id) do
      record = CitableModel.create!(name: "Test")
      PaperTrail.request(whodunnit: alice.id) do
        record.update!(name: "Updated")
      end
      PaperTrail.request(whodunnit: bob.id) do
        record.update!(name: "Updated again")
      end
      assert_equal [
        { "family" => "Zebra", "given" => "Zara" },
        { "family" => "Smith", "given" => "Alice" },
        { "family" => "Brown", "given" => "Bob" }
      ], record.citation['author']
    end
  end

  test "admin user (ADMIN_USER_ID) is always cited as the role label, even when they contribute" do
    admin = create(:user)
    admin.user_profile.update!(full_name: "Zara Admin")
    creator = create(:user)
    creator.user_profile.update!(full_name: "Alice Smith")

    with_env("ADMIN_USER_ID" => admin.id.to_s) do
      PaperTrail.request(whodunnit: creator.id) do
        record = CitableModel.create!(name: "Test")
        PaperTrail.request(whodunnit: admin.id) do
          record.update!(name: "Updated")
        end
        assert_equal [
          { "family" => "Smith", "given" => "Alice" },
          { "literal" => "XRONOS Core Team" }
        ], record.citation['author']
      end
    end
  end

  test "admin is appended as the last author even when not a contributor" do
    admin = create(:user)
    creator = create(:user)
    creator.user_profile.update!(full_name: "Alice Smith")

    with_env("ADMIN_USER_ID" => admin.id.to_s) do
      PaperTrail.request(whodunnit: creator.id) do
        record = CitableModel.create!(name: "Test")
        assert_equal [
          { "family" => "Smith", "given" => "Alice" },
          { "literal" => "XRONOS Core Team" }
        ], record.citation['author']
      end
    end
  end

  test "admin appears as the last author even when not a contributor and has no real name" do
    admin = create(:user)
    admin.user_profile.update!(full_name: nil)
    creator = create(:user)
    creator.user_profile.update!(full_name: "Alice Smith")

    with_env("ADMIN_USER_ID" => admin.id.to_s) do
      PaperTrail.request(whodunnit: creator.id) do
        record = CitableModel.create!(name: "Test")
        assert_equal [
          { "family" => "Smith", "given" => "Alice" },
          { "literal" => "XRONOS Core Team" }
        ], record.citation['author']
      end
    end
  end

  test "creator without a real name is excluded; others remain in alphabetical order" do
    creator = create(:user)
    creator.user_profile.update!(full_name: nil)
    alice = create(:user)
    alice.user_profile.update!(full_name: "Alice Smith")
    bob = create(:user)
    bob.user_profile.update!(full_name: "Bob Brown")

    PaperTrail.request(whodunnit: creator.id) do
      record = CitableModel.create!(name: "Test")
      PaperTrail.request(whodunnit: alice.id) do
        record.update!(name: "Updated")
      end
      PaperTrail.request(whodunnit: bob.id) do
        record.update!(name: "Updated again")
      end
      assert_equal [
        { "family" => "Smith", "given" => "Alice" },
        { "family" => "Brown", "given" => "Bob" }
      ], record.citation['author']
    end
  end

  test "admin user without a real name is included as the XRONOS placeholder" do
    admin = create(:user)
    admin.user_profile.update!(full_name: nil)

    with_env("ADMIN_USER_ID" => admin.id.to_s) do
      PaperTrail.request(whodunnit: admin.id) do
        record = CitableModel.create!(name: "Test")
        assert_equal [{ "literal" => "XRONOS Core Team" }], record.citation['author']
      end
    end
  end

  test "users deleted after editing are silently dropped from the author list" do
    user = create(:user)
    user.user_profile.update!(full_name: "Alice Smith")

    PaperTrail.request(whodunnit: user.id) do
      record = CitableModel.create!(name: "Test")
      user.user_profile.delete
      User.where(id: user.id).delete_all
      assert_equal [{ "literal" => "XRONOS contributors" }], record.citation['author']
    end
  end

  test "format_bibtex returns a BibTeX entry" do
    PaperTrail.request(whodunnit: 1) do
      record = CitableModel.create!(name: "Test")
      bib = record.format_bibtex
      assert_match(/^@dataset\{xronos_citable_test_citable_model_#{record.id},/, bib)
    end
  end

  test "format_bibtex double-braces literal authors" do
    # The {{XRONOS contributors}} and {{XRONOS Core Team}} entries
    # are institutional names; BibTeX needs double braces to keep
    # them as a single literal value (single braces only protect
    # against name-part inversion, not against further parsing).
    PaperTrail.request(whodunnit: 1) do
      record = CitableModel.create!(name: "Test")
      bib = record.format_bibtex
      assert_includes bib, "author = {{XRONOS contributors}}"
    end
  end

  test "format_json returns CSL-JSON" do
    PaperTrail.request(whodunnit: 1) do
      record = CitableModel.create!(name: "Test")
      json = JSON.parse(record.format_json)
      assert_equal "entry", json["type"]
    end
  end

  test "format_yaml returns YAML serialization" do
    PaperTrail.request(whodunnit: 1) do
      record = CitableModel.create!(name: "Test")
      yaml = YAML.safe_load(record.format_yaml, permitted_classes: [Symbol])
      assert_equal "entry", yaml["type"]
    end
  end

  test "format_ris returns a RIS record" do
    PaperTrail.request(whodunnit: 1) do
      record = CitableModel.create!(name: "Test")
      ris = record.format_ris
      assert_match(/^TY  - /, ris)
      assert_match(/^ER  - /, ris)
    end
  end

  private

  def with_env(vars)
    previous = vars.keys.to_h { |k| [k, ENV[k]] }
    vars.each { |k, v| ENV[k] = v }
    yield
  ensure
    previous.each { |k, v| ENV[k] = v }
  end
end
