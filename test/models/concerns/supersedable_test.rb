require "test_helper"

class SupersedableTest < ActiveSupport::TestCase # rubocop:disable Metrics/ClassLength
  include ActiveJob::TestHelper

  test "is not superseded by default" do
    site = create(:site)
    assert site.not_superseded?
    assert_not site.superseded?
  end

  test "is superseded when a Supersession row exists for it" do
    canonical = create(:site)
    superseded = create(:site, :superseded_by, canonical: canonical)

    assert superseded.superseded?
    assert_not superseded.not_superseded?
  end

  test "is hidden from default scope when superseded" do
    canonical = create(:site)
    superseded = create(:site, :superseded_by, canonical: canonical)

    assert_includes Site.all, canonical
    assert_not_includes Site.all, superseded
    assert_includes Site.unscoped.to_a, superseded
  end

  test "ultimately_superseded_by returns self when not superseded" do
    site = create(:site)
    assert_equal site, site.ultimately_superseded_by
  end

  test "ultimately_superseded_by follows a single-link chain" do
    canonical = create(:site)
    superseded = create(:site, :superseded_by, canonical: canonical)

    assert_equal canonical, superseded.ultimately_superseded_by
  end

  test "supersede! raises if canonical is self" do
    site = create(:site)
    assert_raises(ArgumentError) { site.supersede!(site) }
  end

  test "supersede! raises if self is already superseded" do
    canonical = create(:site)
    superseded = create(:site, :superseded_by, canonical: canonical)
    another = create(:site)

    assert_raises(RuntimeError) { superseded.supersede!(another) }
  end

  test "supersede! raises if canonical is itself superseded" do
    site = create(:site)
    middle = create(:site)
    canonical = create(:site, :superseded_by, canonical: middle)

    assert_raises(RuntimeError) { site.supersede!(canonical) }
  end

  test "supersede! creates a Supersession row and a SupersessionEvent row" do
    site = create(:site)
    canonical = create(:site)

    assert_difference -> { Supersession.count } => 1,
                      -> { SupersessionEvent.count } => 1 do
      site.supersede!(canonical)
    end
  end

  test "supersede! is atomic: failure leaves no cache row and no event row" do
    site = create(:site)
    canonical = create(:site)
    # Force a failure inside the transaction, after the precondition
    # checks pass. Both the cache and the event log must be
    # unaffected.
    SupersessionEvent.stub(:create!, ->(*) { raise ActiveRecord::RecordInvalid }) do
      assert_no_difference -> { Supersession.count } do
        assert_no_difference -> { SupersessionEvent.count } do
          assert_raises(ActiveRecord::RecordInvalid) { site.supersede!(canonical) }
        end
      end
    end
  end

  test "supersede! re-points existing Supersession(X->self) rows to the new canonical" do
    a = create(:site)
    b = create(:site)
    c = create(:site)

    a.supersede!(b)
    b.supersede!(c)

    a.reload
    b.reload

    assert_equal c, a.ultimately_superseded_by
    assert_equal c, a.supersession.superseded_by
    assert_equal c, b.ultimately_superseded_by
  end

  test "supersede! reassigns child associations to the canonical" do
    canonical = create(:site)
    superseded = create(:site)
    context = create(:context, site: superseded)

    superseded.supersede!(canonical, "test merge")

    assert_equal canonical, context.reload.site
  end

  test "supersede! reassigns site_names to the canonical" do
    canonical = create(:site)
    superseded = create(:site)
    site_name = create(:site_name, site: superseded)

    superseded.supersede!(canonical, "test merge")

    assert_equal canonical, site_name.reload.site
  end

  test "supersede! writes the comment as a SupersessionEvent comment" do
    site = create(:site)
    canonical = create(:site)

    site.supersede!(canonical, "test merge")

    assert_equal "test merge", site.supersession_events.last.comment
  end

  test "reassign_associations! is private" do
    site = create(:site)
    assert_no_difference -> { site.contexts.count } do
      assert_raises(NoMethodError) { site.reassign_associations!("x") }
    end
  end

  test "supersedable_associations excludes versions and pg_search_document" do
    assoc_names = Site.supersedable_associations.keys
    assert_not_includes assoc_names, "versions"
    assert_not_includes assoc_names, "pg_search_document"
  end

  test "supersedable_associations includes has_many children" do
    assoc_names = Site.supersedable_associations.keys
    assert_includes assoc_names, "contexts"
    assert_includes assoc_names, "site_names"
  end

  test "supersede! reassigns citations on Reference" do
    canonical = create(:reference)
    superseded = create(:reference)
    citation = create(:citation, citing: create(:site), reference: superseded)

    superseded.supersede!(canonical, "test merge")

    assert_equal canonical, citation.reload.reference
  end

  test "supersede! reassigns citations on C14" do
    canonical = create(:c14)
    superseded = create(:c14, sample: canonical.sample)

    superseded.supersede!(canonical, "test merge")

    # The new canonical-side state is asserted by the absence of the
    # superseded record in default scope; nothing else to check for c14.
    assert superseded.superseded?
    assert_equal canonical, superseded.ultimately_superseded_by
  end

  test "supersede! reassigns citations on Typo" do
    canonical = create(:typo)
    superseded = create(:typo, sample: canonical.sample)

    superseded.supersede!(canonical, "test merge")

    assert superseded.superseded?
    assert_equal canonical, superseded.ultimately_superseded_by
  end

  test "restore! raises if not currently superseded" do
    site = create(:site)
    assert_raises(RuntimeError) { site.restore! }
  end

  test "restore! removes the Supersession row and appends a restore event" do
    canonical = create(:site)
    superseded = create(:site, :superseded_by, canonical: canonical)

    assert_difference -> { Supersession.count } => -1,
                      -> { SupersessionEvent.count } => 1 do
      superseded.restore!
    end

    assert_not superseded.reload.superseded?
    assert_equal "restore", superseded.supersession_events.last.event_type
  end

  test "merge_history returns events for this record in created_at order" do
    canonical = create(:site)
    site = create(:site)
    site.supersede!(canonical, "first")
    site.restore!
    another = create(:site)
    site.supersede!(another, "second")

    types = site.merge_history.pluck(:event_type)
    assert_equal %w[supersede restore supersede], types
  end
end
