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

    def polymorphic_url(*)
      "http://example.com/citable_models/#{id}"
    end
  end

  test "citation returns a BibTeX::Entry" do
    PaperTrail.request(whodunnit: 1) do
      record = CitableModel.create!(name: "Test")
      assert_kind_of BibTeX::Entry, record.citation
    end
  end

  test "citation is a :dataset entry with a model-prefixed key" do
    PaperTrail.request(whodunnit: 1) do
      record = CitableModel.create!(name: "Test")
      assert_equal :dataset, record.citation.type
      assert_equal "xronos_citable_test_citable_model_#{record.id}", record.citation.key
    end
  end

  test "citation year is the current year" do
    PaperTrail.request(whodunnit: 1) do
      record = CitableModel.create!(name: "Test")
      assert_equal Time.current.year, record.citation.year.to_i
    end
  end

  test "citation title defaults to model name and id" do
    PaperTrail.request(whodunnit: 1) do
      record = CitableModel.create!(name: "Test")
      assert_equal "XRONOS citable_test_citable_model ##{record.id}", record.citation.title
    end
  end

  test "citation url is the polymorphic URL" do
    PaperTrail.request(whodunnit: 1) do
      record = CitableModel.create!(name: "Test")
      assert_equal "http://example.com/citable_models/#{record.id}", record.citation.url
    end
  end

  test "citation publisher is the XRONOS project name" do
    PaperTrail.request(whodunnit: 1) do
      record = CitableModel.create!(name: "Test")
      assert_equal "XRONOS: An Open Data Infrastructure for Archaeological Chronology",
        record.citation.publisher
    end
  end

  test "citation urldate is the current time" do
    freeze_time = Time.zone.local(2026, 6, 29, 12, 0, 0)
    travel_to(freeze_time) do
      PaperTrail.request(whodunnit: 1) do
        record = CitableModel.create!(name: "Test")
        assert_equal freeze_time.to_s, record.citation.urldate.to_s
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
      assert_equal "Alice Smith", record.citation.author
    end
  end

  test "contributors without a real name are excluded" do
    user = create(:user)
    user.user_profile.update!(full_name: nil)

    PaperTrail.request(whodunnit: user.id) do
      record = CitableModel.create!(name: "Test")
      assert_equal "{XRONOS contributors}", record.citation.author
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
      assert_equal "Zara Zebra and Alice Smith and Bob Brown", record.citation.author
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
        assert_equal "Alice Smith and {XRONOS Core Team}", record.citation.author
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
        assert_equal "Alice Smith and {XRONOS Core Team}", record.citation.author
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
        assert_equal "Alice Smith and {XRONOS Core Team}", record.citation.author
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
      assert_equal "Alice Smith and Bob Brown", record.citation.author
    end
  end

  test "admin user without a real name is included as the XRONOS placeholder" do
    admin = create(:user)
    admin.user_profile.update!(full_name: nil)

    with_env("ADMIN_USER_ID" => admin.id.to_s) do
      PaperTrail.request(whodunnit: admin.id) do
        record = CitableModel.create!(name: "Test")
        assert_equal "{XRONOS Core Team}", record.citation.author
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
      assert_equal "{XRONOS contributors}", record.citation.author
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
