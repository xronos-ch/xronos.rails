module Duplicable

  extend ActiveSupport::Concern
  
  @@duplicable_attrs = []

  included do # instance methods

    def duplicates
      self.class.where(duplicated)
    end

    def is_duplicated?
      duplicates.count > 1
    end

    private

    def duplicated
      filter = attributes
        .with_indifferent_access
        .slice(*duplicable_attrs)

      filter.map { |attr,val|
        if duplicable_opts.has_key?(attr.to_sym)
          [attr, [val, nil]]
        else
          [attr, val]
        end
      }.to_h
    end

    def duplicable_attrs
      self.class.duplicable_attrs
    end

    def duplicable_opts
      self.class.duplicable_opts
    end

  end

  class_methods do

    def duplicable(*attrs)
      @@duplicable_attrs.push(*attrs)
    end

    def duplicable_attrs
      @@duplicable_attrs.map { 
        |x| x.is_a?(Hash) ? x.keys : x 
      }.flatten
    end

    def duplicable_opts
      @@duplicable_attrs
        .filter { |x| x.is_a?(Hash) }
        .reduce({}, :merge)
    end

    def all_duplicated
      # Ugly and postgres-specific, but can't find a better way :(
      duplicated_ids = self
        .group(duplicable_attrs)
        .having("COUNT(*) > 1")
        .select('UNNEST(ARRAY_AGG("id"))')

      self.where(id: duplicated_ids).order(duplicable_attrs)
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
    end

  end

end
