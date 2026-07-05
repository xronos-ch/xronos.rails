module Duplicable # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  # Per-class lists of duplicate-detection attributes, held as class
  # instance variables so each class gets its own (no sharing between
  # parent and subclasses).
  #
  # Exact duplicates use a conservative nil default (nil != nil) with
  # per-attribute opt-in via the `:nil_matches_nil` option. Potential
  # duplicates use fuzzy matching with per-attribute options (`:ci`,
  # `:null`, `:whitespace`, `:mojibake`).
  class_methods do # rubocop:disable Metrics/BlockLength
    def exact_duplicates_attrs_list
      @exact_duplicates_attrs_list ||= []
    end

    def potential_duplicates_attrs_list
      @potential_duplicates_attrs_list ||= []
    end

    # Declare attributes used for exact duplicate detection.
    # Default: nil != nil for any attribute. Opt-in per attribute with
    # `:nil_matches_nil` to make nil == nil for that attribute.
    def exact_duplicates_on(*attrs)
      exact_duplicates_attrs_list.concat(attrs)
    end

    def exact_duplicates_attrs
      exact_duplicates_attrs_list.flat_map { |x| x.is_a?(Hash) ? x.keys : x }
    end

    def exact_duplicates_attrs_with_options
      exact_duplicates_attrs_list
        .filter { |x| x.is_a?(Hash) }
        .reduce({}, :merge)
    end

    # Attributes that have the `:nil_matches_nil` option set.
    def exact_duplicates_nil_matches_nil
      exact_duplicates_attrs_list
        .filter { |x| x.is_a?(Hash) }
        .flat_map { |hash| hash.select { |_, opts| nil_matches_nil?(opts) }.keys }
    end

    # Accepts either a bare symbol (e.g. `bp: :nil_matches_nil`) or an
    # array of options (e.g. `bp: [:nil_matches_nil]`).
    def nil_matches_nil?(opts)
      return true if opts == :nil_matches_nil
      return false unless opts.respond_to?(:include?)

      opts.include?(:nil_matches_nil)
    end

    # Declare attributes used for potential (fuzzy) duplicate detection.
    # Options per attribute: `:ci`, `:null`, `:whitespace`, `:mojibake`.
    def potential_duplicates_on(*attrs)
      potential_duplicates_attrs_list.concat(attrs)
    end

    def potential_duplicates_attrs
      potential_duplicates_attrs_list.flat_map { |x| x.is_a?(Hash) ? x.keys : x }
    end

    def potential_duplicates_attrs_with_options
      potential_duplicates_attrs_list
        .filter { |x| x.is_a?(Hash) }
        .reduce({}, :merge)
    end
  end

  included do # instance methods # rubocop:disable Metrics/BlockLength
    def exact_duplicates
      return self.class.none if exact_duplicates_guarded_by_nil?

      attrs = attributes.with_indifferent_access
      self.class.where(attrs.slice(*self.class.exact_duplicates_attrs))
          .where.not(id: id)
    end

    # Oldest non-superseded record with the same exact-duplicate keys.
    # Returns nil if no other record shares them.
    def find_exact_duplicate
      return nil if exact_duplicates_guarded_by_nil?

      attrs = attributes.with_indifferent_access
      self.class.where(self.class.exact_duplicates_attrs.index_with { |a| attrs[a] })
          .where.not(id: id)
          .order(:created_at, :id)
          .first
    end

    def is_exact_duplicate?
      exact_duplicates.exists?
    end

    def potential_duplicates
      self.class.potential_duplicates_attrs_list.map { |attr|
        where_potential_duplicate(attr)
      }.reduce(:merge)
    end

    def is_potential_duplicate?
      potential_duplicates.count > 1
    end

    protected

    # Conservative nil handling: if any exact-duplicate attribute is nil
    # and doesn't have the `:nil_matches_nil` opt-in, no exact duplicates exist.
    def exact_duplicates_guarded_by_nil?
      attrs = attributes.with_indifferent_access
      nil_safe = self.class.exact_duplicates_nil_matches_nil
      self.class.exact_duplicates_attrs.any? { |k| attrs[k].nil? && !nil_safe.include?(k) }
    end

    def where_potential_duplicate(attr)
      unless attr.is_a?(Hash)
        where_potential_duplicate_exact(attr)
      else
        where_potential_duplicate_with_options(attr)
      end
    end

    def where_potential_duplicate_exact(attr)
        val = attributes.with_indifferent_access[attr]
        self.class.where({attr => val})
    end

    # TODO: document these options

    def where_potential_duplicate_with_options(attr_with_options) # rubocop:disable Metrics/MethodLength
        opts = attr_with_options.values.flatten
        attr = attr_with_options.keys.first

        filters = opts.map { |opt|
          case opt
          when :null
            where_potential_duplicate_null(attr)
          when :ci
            where_potential_duplicate_ilike(attr)
          when :whitespace
            where_potential_duplicate_whitespace(attr)
          when :mojibake
            where_potential_duplicate_mojibake(attr)
          else
            raise "Unknown potential_duplicates_on option: #{opt}"
          end
        }

        filters.reduce(where_potential_duplicate_exact(attr), :or)
    end

    def where_potential_duplicate_null(attr)
        val = attributes.with_indifferent_access[attr]
        unless val.nil?
          self.class.where(attr => nil)
        else
          self.class.where("#{attr} IS NOT NULL")
        end
    end

    def where_potential_duplicate_ilike(attr)
        val = attributes.with_indifferent_access[attr]
        arel_attr = self.class.arel_table[attr.to_sym]
        self.class.where(arel_attr.matches(val))
    end

    def where_potential_duplicate_whitespace(attr)
      val = attributes.with_indifferent_access[attr]
      val_sans_whitespace = val.gsub(/\s/, '%')

      arel_attr = self.class.arel_table[attr.to_sym]
      self.class.where(arel_attr.matches(val_sans_whitespace))
    end

    def where_potential_duplicate_mojibake(attr)
      val = attributes.with_indifferent_access[attr]
      val_sans_nonascii = val.gsub(/[[:^ascii:]]/, '%')

      arel_attr = self.class.arel_table[attr.to_sym]
      self.class.where(arel_attr.matches(val_sans_nonascii))
    end
  end
end
