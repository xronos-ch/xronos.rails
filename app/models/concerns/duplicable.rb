module Duplicable

  extend ActiveSupport::Concern
  
  @@duplicable_attrs = []

  included do # instance methods

    def duplicates
      @@duplicable_attrs.map { |attr|
        where_duplicated(attr)
      }.reduce(:merge)
    end

    def is_duplicated?
      duplicates.count > 1
    end

    protected

    def where_duplicated(attr)
      unless attr.is_a?(Hash)
        where_exactly_duplicated(attr)
      else
        where_duplicated_with_options(attr)
      end
    end

    def where_exactly_duplicated(attr)
        val = attributes.with_indifferent_access[attr]
        self.class.where(["#{attr} = ?", val])
    end

    # TODO: document these options
    
    def where_duplicated_with_options(attr_with_options)
        opts = attr_with_options.values.flatten
        attr = attr_with_options.keys.first

        filters = opts.map { |opt| 
          case opt
          when :null
            where_null(attr)
          when :ci
            where_ilike(attr)
          when :whitespace
            where_whitespace(attr)
          when :mojibake
            where_mojibake(attr)
          else
            raise "Unknown duplicable option: #{opt}"
          end
        }

        filters.reduce(where_exactly_duplicated(attr), :or)
    end

    def where_null(attr)
        self.class.where("#{attr} IS NULL")
    end

    def where_ilike(attr)
        val = attributes.with_indifferent_access[attr]
        arel_attr = self.class.arel_table[attr.to_sym]
        self.class.where(arel_attr.matches(val))
    end

    def where_whitespace(attr)
      val = attributes.with_indifferent_access[attr]
      val_sans_whitespace = val.gsub(/\s/, '%')

      arel_attr = self.class.arel_table[attr.to_sym]
      self.class.where(arel_attr.matches(val_sans_whitespace))
    end

    def where_mojibake(attr)
      val = attributes.with_indifferent_access[attr]
      val_sans_nonascii = val.gsub(/[\u0080-\u00ff]/, '%')

      arel_attr = self.class.arel_table[attr.to_sym]
      self.class.where(arel_attr.matches(val_sans_nonascii))
    end

    private

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
      @@duplicable_attrs
    end

    def duplicable_attrs_without_options
      @@duplicable_attrs.map { 
        |x| x.is_a?(Hash) ? x.keys : x 
      }.flatten
    end

    def duplicable_attrs_with_options
      @@duplicable_attrs
        .filter { |x| x.is_a?(Hash) }
        .reduce({}, :merge)
    end

    def all_duplicates
    end

    def all_exact_duplicates
      duplicated_ids = self
        .group(duplicable_attrs_without_options)
        .having("COUNT(*) > 1")
        .select('UNNEST(ARRAY_AGG("id"))')

      self.where(id: duplicated_ids).order(duplicable_attrs_without_options)
    end

    def merge_duplicates(duplicates)
      # TODO: resolve records when attributes present and nil
      original = duplicates.first
      dupes = duplicates.drop(1)
      dupes.each do |dupe| 
        dupe.superseded_by = original.id # TODO: why .id here??
        dupe.revision_comment = "Merged with #{original.model_name.singular}:#{original.id}"
        dupe.save!
      end
      return original
    end

    #TODO automerge (exact?) duplicates

  end

end
