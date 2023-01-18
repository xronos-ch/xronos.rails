module Duplicable

  extend ActiveSupport::Concern
  
  @@duplicable_attrs = []

  included do # instance methods

    def duplicates
      # TODO: can we make rails use a subquery for this, instead of two queries?
      attrs = attributes.with_indifferent_access
      self.class.where(attrs.slice(*@@duplicable_attrs))
    end

    def is_duplicated?
      duplicates.count > 1
    end

  end

  class_methods do

    def duplicable(attr)
      @@duplicable_attrs << attr
    end
  
    def all_duplicated
      # Ugly and postgres-specific, but can't find a better way :(
      duplicated_ids = self
        .group(@@duplicable_attrs)
        .having("COUNT(*) > 1")
        .select('UNNEST(ARRAY_AGG("id"))')

      self.where(id: duplicated_ids)
    end

  end

end
