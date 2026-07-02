module Supersedable
  # Reflections excluded from reassignment: `versions` (paper_trail metadata
  # must not be rewritten) and `pg_search_document` (managed separately by
  # pg_search).
  EXCLUDED_REFLECTIONS = %w[versions pg_search_document].freeze

  extend ActiveSupport::Concern

  included do # instance methods # rubocop:disable Metrics/BlockLength
    default_scope { where(superseded_by: nil) }

    def supersedable?
      true
    end

    def superseded?
      superseded_by.present?
    end

    def not_superseded?
      superseded_by.blank?
    end

    # Follows the superseded_by chain to the canonical (non-superseded)
    # record. Bypasses the default scope by using unscoped.
    def ultimately_superseded_by
      if superseded_by.present?
        self.class.unscoped.find(superseded_by).ultimately_superseded_by
      else
        self.class.find(id)
      end
    end

    # Reassign all eligible child associations to this record's canonical
    # target (its `superseded_by`). Caller is responsible for setting
    # `superseded_by` first.
    def reassign_associations(revision_comment = nil)
      raise 'Attempt to reassign associations of record that is not superseded.' unless superseded?

      self.class.supersedable_associations.each_value do |reflection|
        reassign_one(reflection, revision_comment)
      end

      true
    end

    private

    def reassign_one(reflection, revision_comment)
      if reflection.is_a?(ActiveRecord::Reflection::HasAndBelongsToManyReflection)
        reassign_many_to_many(reflection, revision_comment)
      else
        reassign_one_to_many(reflection, revision_comment)
      end
    end

    def reassign_one_to_many(reflection, revision_comment)
      revision_comment ||= default_revision_comment
      foreign_key = self.class.foreign_key_for_reflection(reflection)
      send(reflection.name).each do |child|
        child.write_attribute(foreign_key, superseded_by)
        child.revision_comment = revision_comment if child.respond_to?(:revision_comment=)
        child.save!
      end
    end

    # HABTM reassignment is not implemented yet; would require
    # building/destroying join rows.
    def reassign_many_to_many(_reflection, _revision_comment)
      # TODO
    end

    def default_revision_comment
      "#{self.class.model_name.singular}:#{id} has been superseded by " \
        "#{self.class.model_name.singular}:#{superseded_by}"
    end
  end

  class_methods do
    # Returns the set of reflections whose child records should be
    # reassigned when a record is merged into its canonical target.
    def supersedable_associations
      eligible = reflections.reject { |k, _v| EXCLUDED_REFLECTIONS.include?(k) }
      eligible.select { |_k, v| child_association?(v) }
    end

    def child_association?(reflection)
      reflection.is_a?(ActiveRecord::Reflection::HasOneReflection) ||
        reflection.is_a?(ActiveRecord::Reflection::HasManyReflection) ||
        reflection.is_a?(ActiveRecord::Reflection::HasAndBelongsToManyReflection)
    end

    def foreign_key_for_reflection(reflection)
      if reflection.respond_to?(:foreign_key) && reflection.foreign_key
        reflection.foreign_key.to_s
      elsif reflection.options.key?(:as)
        "#{reflection.options[:as]}_id"
      else
        "#{model_name.param_key}_id"
      end
    end
  end
end
