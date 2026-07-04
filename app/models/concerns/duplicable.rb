module Duplicable # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  # Per-class list of duplicate key attributes. Subclasses inherit and
  # can reset via `self._duplicable_attrs_list = []`.
  included do # instance methods # rubocop:disable Metrics/BlockLength
    class_attribute :_duplicable_attrs_list, default: nil
    self._duplicable_attrs_list = []

    def duplicates
      _duplicable_attrs_list.map { |attr|
        where_duplicated(attr)
      }.reduce(:merge)
    end

    def exact_duplicates
      attrs = attributes.with_indifferent_access
      self.class.where(attrs.slice(*duplicable_attrs_without_options))
    end

    # Oldest non-superseded record with the same duplicate keys.
    # Returns nil if none found.
    def find_exact_duplicate
      keys = duplicable_attrs_without_options
      self.class.where(keys.index_with { |a| self[a] })
          .where.not(id: id)
          .order(:created_at, :id)
          .first
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

    def where_duplicated_with_options(attr_with_options) # rubocop:disable Metrics/MethodLength
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

  class_methods do # rubocop:disable Metrics/BlockLength
    def duplicable(*attrs)
      _duplicable_attrs_list.concat(attrs)
    end

    def duplicable_attrs
      _duplicable_attrs_list
    end

    def duplicable_attrs_without_options
      _duplicable_attrs_list.map {
        |x| x.is_a?(Hash) ? x.keys : x
      }.flatten
    end

    def duplicable_attrs_with_options
      _duplicable_attrs_list
        .filter { |x| x.is_a?(Hash) }
        .reduce({}, :merge)
    end

    def all_duplicated
      # Ugly and postgres-specific, but can't find a better way :(
      duplicated_ids = self
        .group(duplicable_attrs_without_options)
        .having("COUNT(*) > 1")
        .select('UNNEST(ARRAY_AGG("id"))')

      self.where(id: duplicated_ids)
    end
  end
end
