class TightenLinkedResourceUniqueness < ActiveRecord::Migration[8.0]
  # Tighten the unique index on linked_resources from
  # (linkable_type, linkable_id, source, external_id) to
  # (linkable_type, linkable_id, source): at most one link per
  # record per source.
  #
  # If any (linkable, source) group currently has more than one row
  # (e.g. multiple Wikidata matches for a site, accumulated by
  # BatchMatchableToWikidata), the index creation would fail. We
  # auto-merge those duplicates first: keep an "approved" row if one
  # exists, otherwise the most recently updated row, and delete the
  # rest.
  #
  # The down migration restores the old index but does not recreate
  # the deleted duplicate rows — they are gone for good.
  def up
    merge_duplicate_links
    swap_unique_index
  end

  def down
    remove_index :linked_resources, name: 'index_linked_resources_on_linkable_and_source'
    add_index :linked_resources, %i[linkable_type linkable_id source external_id],
              unique: true, name: 'index_linked_resources_on_polymorphic_source_and_external_id'
  end

  private

  def merge_duplicate_links
    duplicate_groups.each { |attrs| merge_group(*attrs) }
  end

  def duplicate_groups
    LinkedResource
      .group(:linkable_type, :linkable_id, :source)
      .having('COUNT(*) > 1')
      .pluck(:linkable_type, :linkable_id, :source)
  end

  def merge_group(linkable_type, linkable_id, source)
    duplicates = LinkedResource
                 .where(linkable_type: linkable_type, linkable_id: linkable_id, source: source)
                 .order(Arel.sql("CASE WHEN status = 'approved' THEN 0 ELSE 1 END"), updated_at: :desc, id: :asc)
    keeper = duplicates.first
    duplicates.where.not(id: keeper.id).destroy_all
  end

  def swap_unique_index
    remove_index :linked_resources, name: 'index_linked_resources_on_polymorphic_source_and_external_id'
    add_index :linked_resources, %i[linkable_type linkable_id source],
              unique: true, name: 'index_linked_resources_on_linkable_and_source'
  end
end
