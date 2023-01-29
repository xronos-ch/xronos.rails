module Duplicable

  extend ActiveSupport::Concern
  
  @@duplicable_attrs = []

  included do # instance methods

    def duplicates
      @@duplicable_attrs.map { |attr|
        where_duplicated(attr)
      }.reduce(:merge)
    end

    def exact_duplicates
      attrs = attributes.with_indifferent_access
      self.class.where(attrs.slice(*duplicable_attrs_without_options))
    end

    def is_duplicated?
      exact_duplicates.count > 1 || duplicates.count > 1
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
        self.class.where({attr => val})
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
        val = attributes.with_indifferent_access[attr]
        unless val.nil?
          self.class.where(attr => nil)
        else
          self.class.where("#{attr} IS NOT NULL")
        end
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
      val_sans_nonascii = val.gsub(/[[:^ascii:]]/, '%')

      arel_attr = self.class.arel_table[attr.to_sym]
      self.class.where(arel_attr.matches(val_sans_nonascii))
    end

    private

    def duplicable_attrs
      self.class.duplicable_attrs
    end

    def duplicable_attrs_without_options
      self.class.duplicable_attrs_without_options
    end

    def duplicable_attrs_with_options
      self.class.duplicable_attrs_with_options
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

    def duplicated
      # TODO
    end

    def exactly_duplicated
      duplicated_ids = where_exactly_duplicated
        .select('UNNEST(ARRAY_AGG("id"))')
      self.where(id: duplicated_ids)
    end

    def exactly_duplicated_grouped
      where_exactly_duplicated
        .pluck('ARRAY_AGG("id")')
        .map do |ids|
          self.where(id: ids)
        end
    end

    def merge_all_exact_duplicates
      exactly_duplicated_grouped.each do |dupes|
        merge_exact_duplicates(dupes)
      end
      return exactly_duplicated.count
    end

    def merge_exact_duplicates(dupes)
      model = dupes.first.model_name
      merge_comment = "Merged #{model.plural} #{dupes.ids.to_sentence}"

      merged = dupes.order(:created_at).first.dup
      merged.superseded_by = nil # in case it has been merged before
      merged.paper_trail_event = "merge"
      merged.revision_comment = merge_comment
      merged.save!

      dupes = dupes.where.not(id: merged.id) # otherwise dupes includes the new record...

      merge_comment = merge_comment + " to #{model.singular}:#{merged.id}"
      dupes.each do |dupe|
        dupe.superseded_by = merged.id # TODO: why .id here??
        dupe.paper_trail_event = "merge"
        dupe.revision_comment = merge_comment
        dupe.save!

        dupe.reassign_associations(merge_comment)
      end

      return merged
    end

    private

    def where_exactly_duplicated
      group(duplicable_attrs_without_options)
        .having("COUNT(*) > 1")
    end

  end

end
