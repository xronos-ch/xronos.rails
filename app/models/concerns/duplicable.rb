module Duplicable

  extend ActiveSupport::Concern
  
  @@duplicable_attrs = []

  included do # instance methods

    def duplicates
      attrs = attributes.with_indifferent_access
      self.class.where(attrs.slice(*@@duplicable_attrs))
    end

    def is_duplicated?
      duplicates.count > 1
    end

  end

  class_methods do

    def duplicable(*attrs)
      @@duplicable_attrs.push(*attrs)
    end
  
    def all_duplicated
      # Ugly and postgres-specific, but can't find a better way :(
      duplicated_ids = self
        .group(@@duplicable_attrs)
        .having("COUNT(*) > 1")
        .select('UNNEST(ARRAY_AGG("id"))')

      self.where(id: duplicated_ids)
    end

    def merge_duplicates(duplicates)
      original = duplicates.first
      dupes = duplicates.drop(1)
      dupes.each do |dupe| 
        dupe.superseded_by = original.id # TODO: why .id here??
        dupe.revision_comment = "Merged with #{original.model_name.singular}:#{original.id}"
        dupe.save!
      end
      return original
      # todo: paper_trail
    end

  end

end
