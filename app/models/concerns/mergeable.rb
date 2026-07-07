# frozen_string_literal: true

# Builds on `Duplicable` to add the merge operation. Models handle
# child reassociation via `before_merge :method`. Auto-merge on
# save is opt-in via `after_save :merge_exact_duplicates`.
module Mergeable
  extend ActiveSupport::Concern

  included do
    include Duplicable
    define_callbacks :merge
    attr_accessor :merged_into_id
  end

  class_methods do
    def before_merge(*methods, &block)
      set_callback :merge, :before, *methods, &block
    end

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

    # Group by exact-duplicate attrs, having COUNT(*) > 1. Mirrors
    # `Duplicable#duplicates_except`'s nil guard: records with `nil`
    # in any strict (non-`:nil_matches_nil`) attribute are not
    # exact duplicates, so the rake task must not merge them either.
    # The cross-sample path (when present) handles the `nil` case
    # separately.
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
    # `Supersession.exists?` is used (not `superseded?`) so the
    # `supersession` association cache is not populated before
    # downstream callbacks (e.g. FactoryBot trait hooks) have a
    # chance to create the Supersession row.
    return if respond_to?(:superseded?) && Supersession.exists?(superseded: self)

    dupe = find_exact_duplicate
    return unless dupe

    merge_with_duplicate(dupe)
  end

  # Available to `before_merge` callbacks.
  def canonical
    self.class.find(merged_into_id)
  end

  protected

  # Shared by `merge_exact_duplicates` and subclass callbacks (e.g.
  # Chron's cross-sample fallback).
  def merge_with_duplicate(dupe)
    self_at  = created_at || Time.at(0)
    dupe_at  = dupe.created_at || Time.at(0)

    canonical_is_self = self_at < dupe_at || (self_at == dupe_at && id <= dupe.id)

    if canonical_is_self
      dupe.merge_into!(self)
    else
      merge_into!(dupe)
    end
  end

  def perform_merge!(canonical)
    if respond_to?(:supersede!, true)
      comment = respond_to?(:revision_comment) ? revision_comment : nil
      supersede!(canonical, comment)
    else
      destroy
    end
  end
end
