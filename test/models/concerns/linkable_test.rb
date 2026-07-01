# frozen_string_literal: true

require "test_helper"

class LinkableTest < ActiveSupport::TestCase
  # Disposable schema for the test host class
  setup do
    ActiveRecord::Schema.define do
      suppress_messages do
        create_table :linkable_test_hosts, force: true do |t|
          t.timestamps
        end
      end
    end
  end

  teardown do
    ActiveRecord::Base.connection.drop_table(:linkable_test_hosts) if ActiveRecord::Base.connection.table_exists?(:linkable_test_hosts)
  end

  # Test-only host model — uses the real Wikidata source registered at app boot.
  class LinkableTestHost < ApplicationRecord
    self.table_name = "linkable_test_hosts"

    has_many :linked_resources, as: :linkable, dependent: :destroy

    include Linkable
    linkable_to :wikidata
  end

  # Parallel test-only host model — uses the real Pleiades source to
  # exercise the linkable_to macro on a second, non-Wikidata source.
  class LinkablePleiadesTestHost < ApplicationRecord
    self.table_name = "linkable_test_hosts"

    has_many :linked_resources, as: :linkable, dependent: :destroy

    include Linkable
    linkable_to :pleiades
  end

  # Parallel test-only host model — uses the real Vici.org source.
  class LinkableViciTestHost < ApplicationRecord
    self.table_name = "linkable_test_hosts"

    has_many :linked_resources, as: :linkable, dependent: :destroy

    include Linkable
    linkable_to :vici
  end

  # --- Macro: per-source methods ---

  test "linkable_to defines a reader for the linked resource" do
    host = LinkableTestHost.create!
    link = host.linked_resources.create!(source: "Wikidata", external_id: "Q42")
    assert_equal link, host.wikidata_link
  end

  test "linkable_to defines a missing? predicate that is true when no link exists" do
    host = LinkableTestHost.create!
    assert host.missing_wikidata_link?
  end

  test "linkable_to defines a missing? predicate that is false when a link exists" do
    host = LinkableTestHost.create!
    host.linked_resources.create!(source: "Wikidata", external_id: "Q42")
    refute host.missing_wikidata_link?
  end

  test "linkable_to defines a pending? predicate that is true when the link is pending" do
    host = LinkableTestHost.create!
    host.linked_resources.create!(source: "Wikidata", external_id: "Q42", status: "pending")
    assert host.pending_wikidata_link?
  end

  test "linkable_to defines a pending? predicate that is false when the link is approved" do
    host = LinkableTestHost.create!
    host.linked_resources.create!(source: "Wikidata", external_id: "Q42", status: "approved")
    refute host.pending_wikidata_link?
  end

  test "linkable_to defines a missing? scope" do
    with_link = LinkableTestHost.create!
    with_link.linked_resources.create!(source: "Wikidata", external_id: "Q42")
    without_link = LinkableTestHost.create!

    result = LinkableTestHost.missing_wikidata_link
    assert_includes result, without_link
    refute_includes result, with_link
  end

  test "linkable_to defines a pending? scope" do
    pending_host = LinkableTestHost.create!
    pending_host.linked_resources.create!(source: "Wikidata", external_id: "Q42", status: "pending")
    approved_host = LinkableTestHost.create!
    approved_host.linked_resources.create!(source: "Wikidata", external_id: "Q43", status: "approved")

    result = LinkableTestHost.pending_wikidata_link
    assert_includes result, pending_host
    refute_includes result, approved_host
  end

  test "linkable_to raises when called with an unknown source key" do
    error = assert_raises(RuntimeError) do
      Class.new(ApplicationRecord) do
        self.table_name = "linkable_test_hosts"
        include Linkable
        linkable_to :does_not_exist
      end
    end
    assert_match(/Unknown linked resource source/, error.message)
  end

  # --- Class-level issues list ---

  test "class.linked_resource_issues contains the issue symbols for each registered source" do
    assert_includes LinkableTestHost.linked_resource_issues, :missing_wikidata_link
    assert_includes LinkableTestHost.linked_resource_issues, :pending_wikidata_link
  end

  # --- Instance-level issues list ---

  test "instance.linked_resource_issues returns the missing issue when no link exists" do
    host = LinkableTestHost.create!
    assert_equal [ :missing_wikidata_link ], host.linked_resource_issues
  end

  test "instance.linked_resource_issues returns only remaining issues after a link is approved" do
    host = LinkableTestHost.create!
    host.linked_resources.create!(source: "Wikidata", external_id: "Q42", status: "approved")
    assert_equal [], host.linked_resource_issues
  end

  test "instance.linked_resource_issues returns pending when the link is pending" do
    host = LinkableTestHost.create!
    host.linked_resources.create!(source: "Wikidata", external_id: "Q42", status: "pending")
    assert_equal [ :pending_wikidata_link ], host.linked_resource_issues
  end

  test "has_linked_resource_issue? returns the predicate result" do
    host = LinkableTestHost.create!
    host.linked_resources.create!(source: "Wikidata", external_id: "Q42", status: "approved")
    refute host.has_linked_resource_issue?(:missing_wikidata_link)
    refute host.has_linked_resource_issue?(:pending_wikidata_link)
  end

  # --- Pleiades (parallel coverage of the macro on a non-Wikidata source) ---

  test "linkable_to defines a pleiades_link reader" do
    host = LinkablePleiadesTestHost.create!
    link = host.linked_resources.create!(source: "Pleiades", external_id: "687917")
    assert_equal link, host.pleiades_link
  end

  test "linkable_to defines a missing_pleiades_link? predicate" do
    host = LinkablePleiadesTestHost.create!
    assert host.missing_pleiades_link?
    host.linked_resources.create!(source: "Pleiades", external_id: "687917")
    refute host.missing_pleiades_link?
  end

  test "linkable_to defines a pending_pleiades_link? predicate" do
    host = LinkablePleiadesTestHost.create!
    host.linked_resources.create!(source: "Pleiades", external_id: "687917", status: "pending")
    assert host.pending_pleiades_link?
    host.linked_resources.first.update!(status: "approved")
    refute host.pending_pleiades_link?
  end

  test "linkable_to defines a missing_pleiades_link scope" do
    with_link = LinkablePleiadesTestHost.create!
    with_link.linked_resources.create!(source: "Pleiades", external_id: "687917")
    without_link = LinkablePleiadesTestHost.create!

    result = LinkablePleiadesTestHost.missing_pleiades_link
    assert_includes result, without_link
    refute_includes result, with_link
  end

  test "linkable_to defines a pending_pleiades_link scope" do
    pending_host = LinkablePleiadesTestHost.create!
    pending_host.linked_resources.create!(source: "Pleiades", external_id: "687917", status: "pending")
    approved_host = LinkablePleiadesTestHost.create!
    approved_host.linked_resources.create!(source: "Pleiades", external_id: "423422", status: "approved")

    result = LinkablePleiadesTestHost.pending_pleiades_link
    assert_includes result, pending_host
    refute_includes result, approved_host
  end

  test "class.linked_resource_issues for the Pleiades host has only Pleiades issues" do
    issues = LinkablePleiadesTestHost.linked_resource_issues
    assert_includes issues, :missing_pleiades_link
    assert_includes issues, :pending_pleiades_link
    refute_includes issues, :missing_wikidata_link
    refute_includes issues, :pending_wikidata_link
  end

  test "instance.linked_resource_issues returns the Pleiades missing issue" do
    host = LinkablePleiadesTestHost.create!
    assert_equal [ :missing_pleiades_link ], host.linked_resource_issues
  end

  test "instance.linked_resource_issues returns the Pleiades pending issue" do
    host = LinkablePleiadesTestHost.create!
    host.linked_resources.create!(source: "Pleiades", external_id: "687917", status: "pending")
    assert_equal [ :pending_pleiades_link ], host.linked_resource_issues
  end

  # --- Vici.org (parallel coverage of the macro on a third source) ---

  test "linkable_to defines a vici_link reader" do
    host = LinkableViciTestHost.create!
    link = host.linked_resources.create!(source: "Vici.org", external_id: "57205")
    assert_equal link, host.vici_link
  end

  test "linkable_to defines a missing_vici_link? predicate" do
    host = LinkableViciTestHost.create!
    assert host.missing_vici_link?
    host.linked_resources.create!(source: "Vici.org", external_id: "57205")
    refute host.missing_vici_link?
  end

  test "linkable_to defines a pending_vici_link? predicate" do
    host = LinkableViciTestHost.create!
    host.linked_resources.create!(source: "Vici.org", external_id: "57205", status: "pending")
    assert host.pending_vici_link?
    host.linked_resources.first.update!(status: "approved")
    refute host.pending_vici_link?
  end

  test "linkable_to defines a missing_vici_link scope" do
    with_link = LinkableViciTestHost.create!
    with_link.linked_resources.create!(source: "Vici.org", external_id: "57205")
    without_link = LinkableViciTestHost.create!

    result = LinkableViciTestHost.missing_vici_link
    assert_includes result, without_link
    refute_includes result, with_link
  end

  test "linkable_to defines a pending_vici_link scope" do
    pending_host = LinkableViciTestHost.create!
    pending_host.linked_resources.create!(source: "Vici.org", external_id: "57205", status: "pending")
    approved_host = LinkableViciTestHost.create!
    approved_host.linked_resources.create!(source: "Vici.org", external_id: "12345", status: "approved")

    result = LinkableViciTestHost.pending_vici_link
    assert_includes result, pending_host
    refute_includes result, approved_host
  end

  test "class.linked_resource_issues for the Vici host has only Vici issues" do
    issues = LinkableViciTestHost.linked_resource_issues
    assert_includes issues, :missing_vici_link
    assert_includes issues, :pending_vici_link
    refute_includes issues, :missing_wikidata_link
    refute_includes issues, :pending_wikidata_link
    refute_includes issues, :missing_pleiades_link
    refute_includes issues, :pending_pleiades_link
  end

  test "instance.linked_resource_issues returns the Vici missing issue" do
    host = LinkableViciTestHost.create!
    assert_equal [ :missing_vici_link ], host.linked_resource_issues
  end

  test "instance.linked_resource_issues returns the Vici pending issue" do
    host = LinkableViciTestHost.create!
    host.linked_resources.create!(source: "Vici.org", external_id: "57205", status: "pending")
    assert_equal [ :pending_vici_link ], host.linked_resource_issues
  end
end
