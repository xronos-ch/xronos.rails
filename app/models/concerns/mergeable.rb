# Builds on `Duplicable` to add the merge operation. Including
# `Mergeable` automatically pulls `Duplicable` in. Models handle
# child reassociation via `before_merge :method`. Auto-merge on
# save is opt-in via `after_save :merge_exact_duplicates`.
module Mergeable
  extend ActiveSupport::Concern

  included do
    include Duplicable
    define_callbacks :merge
    attr_accessor :merged_into_id # set on the dupe before mutation
  end

  class_methods do
    def before_merge(*methods, &block)
      set_callback :merge, :before, *methods, &block
    end

    # Merge a group of duplicate records into one canonical.
    def merge_duplicates!(records, canonical: nil)
      raise ArgumentError, 'no records to merge' if records.empty?

      canonical ||= pick_canonical(records)
      duplicates  = records - [canonical]
      return canonical if duplicates.empty?

      transaction do
        duplicates.each { |dupe| dupe.merge_into!(canonical) }
      end

      canonical
    end

    # Scope of duplicate groups (GROUP BY exact-duplicate attrs, having
    # COUNT(*) > 1), used by the `xronos:deduplicate` rake task.
    #
    # Mirrors `Duplicable#exact_duplicates_guarded_by_nil?`: records
    # with `nil` in any strict (non-`:nil_matches_nil`) attribute are
    # not considered exact duplicates by the model, so the rake task
    # must not merge them either. The cross-sample path (when present)
    # handles the `nil` case separately.
    def duplicate_group_scope
      attrs = exact_duplicates_attrs
      strict_attrs = attrs - exact_duplicates_nil_matches_nil

      scope = all
      unless strict_attrs.empty?
        clause = strict_attrs
                 .map { |a| "#{quoted_table_name}.#{connection.quote_column_name(a)} IS NOT NULL" }
                 .join(' AND ')
        scope = scope.where(clause)
      end

      scope.group(*attrs).having('COUNT(*) > 1')
    end

    private

    def pick_canonical(records)
      records.min_by { |r| [r.created_at || Time.at(0), r.id || 0] }
    end
  end

  # Merge self into canonical. Sets `merged_into_id` before mutating.
  def merge_into!(canonical)
    raise ArgumentError, 'cannot merge into self' if canonical == self
    raise ArgumentError, 'canonical must be persisted' unless canonical&.persisted?

    self.merged_into_id = canonical.id
    self.revision_comment = "Merged into #{self.class.name}:#{canonical.id}" if respond_to?(:revision_comment=)

    transaction do
      run_callbacks :merge do
        perform_merge!(canonical)
      end
    end
  end

  def merge_exact_duplicates
    # Guard against re-merging an already-superseded record, e.g. on a
    # second pass of `cross_sample_deduplicate!` after the first pass
    # superseded the dupe. `Supersession.exists?` is used instead of
    # `superseded?` so the `supersession` association cache is not
    # populated before downstream callbacks (e.g. FactoryBot trait
    # hooks) have a chance to create the Supersession row.
    return if respond_to?(:superseded?) && Supersession.exists?(superseded: self)

    dupe = find_exact_duplicate
    return unless dupe

    merge_with_duplicate(dupe)
  end

  # The canonical record this dupe is being merged into. Available
  # to `before_merge` callbacks.
  def canonical
    self.class.find(merged_into_id)
  end

  protected

  # Merge self into `dupe`, choosing canonical by oldest-first. Shared
  # by `merge_exact_duplicates` and any subclass callbacks (e.g. Chron's
  # cross-sample fallback) that need to perform the same dispatch.
  def merge_with_duplicate(dupe)
    self_at  = created_at || Time.at(0)
    dupe_at  = dupe.created_at || Time.at(0)

    # self is canonical if it's older (or same age with lower id).
    canonical_is_self = self_at < dupe_at || (self_at == dupe_at && id <= dupe.id)

    if canonical_is_self
      dupe.merge_into!(self)
    else
      merge_into!(dupe)
    end
  end

  # Dispatch to `supersede!` (Supersedable models) or `destroy`.
  def perform_merge!(canonical)
    if respond_to?(:supersede!, true)
      comment = respond_to?(:revision_comment) ? revision_comment : nil
      supersede!(canonical, comment)
    else
      destroy
    end
  end
end
