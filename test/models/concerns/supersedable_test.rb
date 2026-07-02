require "test_helper"

class SupersedableTest < ActiveSupport::TestCase # rubocop:disable Metrics/ClassLength
  include ActiveJob::TestHelper

  test "is not superseded by default" do
    site = create(:site)
    assert site.not_superseded?
    assert_not site.superseded?
  end

  test "is superseded when superseded_by is set" do
    canonical = create(:site)
    site = create(:site, :superseded, superseded_by_site: canonical)

    assert site.superseded?
    assert_not site.not_superseded?
  end

  test "is hidden from default scope when superseded" do
    canonical = create(:site)
    superseded = create(:site, :superseded, superseded_by_site: canonical)

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
    superseded = create(:site, :superseded, superseded_by_site: canonical)

    assert_equal canonical, superseded.ultimately_superseded_by
  end

  test "ultimately_superseded_by follows a multi-link chain to the canonical" do
    canonical = create(:site)
    middle = create(:site, :superseded, superseded_by_site: canonical)
    leaf = create(:site, :superseded, superseded_by_site: middle)

    assert_equal canonical, leaf.ultimately_superseded_by
  end

  test "reassign_associations moves has_many contexts to the canonical record" do
    canonical = create(:site)
    superseded = create(:site, :superseded, superseded_by_site: canonical)
    context = create(:context, site: superseded)

    with_versioning do
      superseded.reassign_associations("test merge")
    end

    assert_equal canonical, context.reload.site
  end

  test "reassign_associations moves has_many site_names to the canonical record" do
    canonical = create(:site)
    superseded = create(:site, :superseded, superseded_by_site: canonical)
    site_name = create(:site_name, site: superseded)

    with_versioning do
      superseded.reassign_associations("test merge")
    end

    assert_equal canonical, site_name.reload.site
  end

  test "reassign_associations uses the default revision comment when none given" do
    canonical = create(:site)
    superseded = create(:site, :superseded, superseded_by_site: canonical)
    context = create(:context, site: superseded)

    with_versioning do
      superseded.reassign_associations
    end

    assert_match(/superseded by site:#{canonical.id}/, context.versions.last.revision_comment)
  end

  test "reassign_associations raises if not superseded" do
    site = create(:site)
    assert_raises(RuntimeError) { site.reassign_associations }
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

  test "reassign_associations works on Reference, moving citations" do
    canonical = create(:reference)
    superseded = create(:reference, :superseded, superseded_by_reference: canonical)
    citation = create(:citation, citing: create(:site), reference: superseded)

    with_versioning do
      superseded.reassign_associations("test merge")
    end

    assert_equal canonical, citation.reload.reference
  end

  test "reassign_associations works on C14, moving citations" do
    canonical = create(:c14)
    superseded = create(:c14, :superseded, superseded_by_c14: canonical)
    citation = create(:citation, citing: superseded, reference: create(:reference))

    with_versioning do
      superseded.reassign_associations("test merge")
    end

    assert_equal canonical, citation.reload.citing
  end

  test "reassign_associations works on Typo, moving citations" do
    canonical = create(:typo)
    superseded = create(:typo, :superseded, superseded_by_typo: canonical)
    citation = create(:citation, citing: superseded, reference: create(:reference))

    with_versioning do
      superseded.reassign_associations("test merge")
    end

    assert_equal canonical, citation.reload.citing
  end
end
