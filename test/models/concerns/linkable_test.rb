# frozen_string_literal: true

require "test_helper"

# Register a test source for the linkable_to macro tests. Registered at
# file load time so the test host class below can reference it via
# `linkable_to :source_test` at class-definition time. The test source
# is the canonical target for the macro tests, so the macro is exercised
# in isolation from any real, externally-maintained source.
LinkedResource::Source.register :source_test,
  name: "Source Test",
  url_template: "https://test.example/%<id>s",
  id_pattern: /\A\d+\z/,
  description: "Test source for linkable_to"

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

    # Re-register the test source at test runtime. The top-of-file
    # registration (above the class definition) is needed for the
    # LinkableTestHost class to be defined; this re-registration is
    # needed because source_test.rb's teardown removes :source_test
    # from the registry after each of its tests, and the
    # LinkedResource validation looks the source up in the registry
    # at validation time.
    LinkedResource::Source.register :source_test,
      name: "Source Test",
      url_template: "https://test.example/%<id>s",
      id_pattern: /\A\d+\z/,
      description: "Test source for linkable_to"
  end

  teardown do
    ActiveRecord::Base.connection.drop_table(:linkable_test_hosts) if ActiveRecord::Base.connection.table_exists?(:linkable_test_hosts)
  end

  # Test-only host model — uses the test source registered above.
  class LinkableTestHost < ApplicationRecord
    self.table_name = "linkable_test_hosts"

    include Linkable
    linkable_to :source_test
  end

  # --- Macro: per-source methods ---

  test "linkable_to defines a reader for the linked resource" do
    host = LinkableTestHost.create!
    link = host.linked_resources.create!(source: "Source Test", external_id: "42")
    assert_equal link, host.source_test_link
  end

  test "linkable_to defines a missing? predicate that is true when no link exists" do
    host = LinkableTestHost.create!
    assert host.missing_source_test_link?
  end

  test "linkable_to defines a missing? predicate that is false when a link exists" do
    host = LinkableTestHost.create!
    host.linked_resources.create!(source: "Source Test", external_id: "42")
    refute host.missing_source_test_link?
  end

  test "linkable_to defines a pending? predicate that is true when the link is pending" do
    host = LinkableTestHost.create!
    host.linked_resources.create!(source: "Source Test", external_id: "42", status: "pending")
    assert host.pending_source_test_link?
  end

  test "linkable_to defines a pending? predicate that is false when the link is approved" do
    host = LinkableTestHost.create!
    host.linked_resources.create!(source: "Source Test", external_id: "42", status: "approved")
    refute host.pending_source_test_link?
  end

  test "linkable_to defines a missing? scope" do
    with_link = LinkableTestHost.create!
    with_link.linked_resources.create!(source: "Source Test", external_id: "42")
    without_link = LinkableTestHost.create!

    result = LinkableTestHost.missing_source_test_link
    assert_includes result, without_link
    refute_includes result, with_link
  end

  test "linkable_to defines a pending? scope" do
    pending_host = LinkableTestHost.create!
    pending_host.linked_resources.create!(source: "Source Test", external_id: "42", status: "pending")
    approved_host = LinkableTestHost.create!
    approved_host.linked_resources.create!(source: "Source Test", external_id: "43", status: "approved")

    result = LinkableTestHost.pending_source_test_link
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
    assert_includes LinkableTestHost.linked_resource_issues, :missing_source_test_link
    assert_includes LinkableTestHost.linked_resource_issues, :pending_source_test_link
  end

  # --- Instance-level issues list ---

  test "instance.linked_resource_issues returns the missing issue when no link exists" do
    host = LinkableTestHost.create!
    assert_equal [ :missing_source_test_link ], host.linked_resource_issues
  end

  test "instance.linked_resource_issues returns only remaining issues after a link is approved" do
    host = LinkableTestHost.create!
    host.linked_resources.create!(source: "Source Test", external_id: "42", status: "approved")
    assert_equal [], host.linked_resource_issues
  end

  test "instance.linked_resource_issues returns pending when the link is pending" do
    host = LinkableTestHost.create!
    host.linked_resources.create!(source: "Source Test", external_id: "42", status: "pending")
    assert_equal [ :pending_source_test_link ], host.linked_resource_issues
  end

  test "has_linked_resource_issue? returns the predicate result" do
    host = LinkableTestHost.create!
    host.linked_resources.create!(source: "Source Test", external_id: "42", status: "approved")
    refute host.has_linked_resource_issue?(:missing_source_test_link)
    refute host.has_linked_resource_issue?(:pending_source_test_link)
  end
end
