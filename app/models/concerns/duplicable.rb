# frozen_string_literal: true

# Per-class lists of duplicate-detection attributes, held as class
# instance variables so each class gets its own (no sharing between
# parent and subclasses).
#
# Exact duplicates use a conservative nil default (nil != nil) with
# per-attribute opt-in via the `:nil_matches_nil` option. Potential
# duplicates use fuzzy matching with per-attribute options (`:ci`,
# `:null`, `:whitespace`, `:mojibake`).
module Duplicable # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  class_methods do # rubocop:disable Metrics/BlockLength
    def exact_duplicates_attrs_list
      @exact_duplicates_attrs_list ||= []
    end

    def potential_duplicates_attrs_list
      @potential_duplicates_attrs_list ||= []
    end

    # Default: nil != nil for any attribute. Opt in per attribute
    # with `:nil_matches_nil` to make nil == nil for that attribute.
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

    def exact_duplicates_nil_matches_nil
      exact_duplicates_attrs_list
        .filter { |x| x.is_a?(Hash) }
        .flat_map { |hash| hash.select { |_, opts| nil_matches_nil?(opts) }.keys }
    end

    # Accepts `bp: :nil_matches_nil` or `bp: [:nil_matches_nil]`.
    def nil_matches_nil?(opts)
      return true if opts == :nil_matches_nil
      return false unless opts.respond_to?(:include?)

      opts.include?(:nil_matches_nil)
    end

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

    # SQL form of `attr_matches?` (the per-attr nil-handling rule).
    # For each attr: `:nil_matches_nil` → `IS NOT DISTINCT FROM`;
    # otherwise → `=` with `IS NOT NULL` on the current side. Used by
    # `Chron.cross_sample_pair_sql` (and `Sample` for the relaxed
    # sample check) so the nil rule lives in exactly one place.
    def match_conditions(attrs:, current_alias:, other_alias:, quote:)
      nil_safe = attrs.select { |a| nil_matches_nil?(exact_duplicates_attrs_with_options[a.to_sym]) }
      attrs.map do |a|
        c = quote.call(a)
        if nil_safe.include?(a)
          "#{other_alias}.#{c} IS NOT DISTINCT FROM #{current_alias}.#{c}"
        else
          "#{other_alias}.#{c} = #{current_alias}.#{c} AND #{current_alias}.#{c} IS NOT NULL"
        end
      end
    end
  end

  included do # instance methods # rubocop:disable Metrics/BlockLength
    # Records matching `self` on every exact-duplicate attribute except
    # those in `except:`. Empty if any non-`:nil_matches_nil` attribute
    # is nil.
    def duplicates_except(*except)
      attrs    = attributes.with_indifferent_access
      compare  = self.class.exact_duplicates_attrs - except
      nil_safe = self.class.exact_duplicates_nil_matches_nil
      return self.class.none if compare.any? { |a| attrs[a].nil? && !nil_safe.include?(a) }

      self.class.where(compare.index_with { |a| attrs[a] })
          .where.not(id: id)
          .order(:created_at, :id)
    end

    # Nil-matches-nil if the attribute has the `:nil_matches_nil`
    # option, otherwise nil can never match.
    def attr_matches?(other, attr)
      mine   = send(attr)
      theirs = other.send(attr)
      if self.class.nil_matches_nil?(self.class.exact_duplicates_attrs_with_options[attr.to_sym])
        (mine.nil? && theirs.nil?) || mine == theirs
      else
        !mine.nil? && mine == theirs
      end
    end

    def find_exact_duplicate
      duplicates_except.first
    end

    def exact_duplicates
      duplicates_except
    end

    def is_exact_duplicate?
      exact_duplicates.exists?
    end

    def potential_duplicates
      self.class.potential_duplicates_attrs_list.map do |attr|
        where_potential_duplicate(attr)
      end.reduce(:merge)
    end

    def is_potential_duplicate?
      potential_duplicates.count > 1
    end

    protected

    def where_potential_duplicate(attr)
      if attr.is_a?(Hash)
        where_potential_duplicate_with_options(attr)
      else
        where_potential_duplicate_exact(attr)
      end
    end

    def where_potential_duplicate_exact(attr)
      val = attributes.with_indifferent_access[attr]
      self.class.where({ attr => val })
    end

    # TODO: document these options

    def where_potential_duplicate_with_options(attr_with_options) # rubocop:disable Metrics/MethodLength
      opts = attr_with_options.values.flatten
      attr = attr_with_options.keys.first

      filters = opts.map do |opt|
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
      end

      filters.reduce(where_potential_duplicate_exact(attr), :or)
    end

    def where_potential_duplicate_null(attr)
      val = attributes.with_indifferent_access[attr]
      if val.nil?
        self.class.where("#{attr} IS NOT NULL")
      else
        self.class.where(attr => nil)
      end
    end

    def where_potential_duplicate_ilike(attr)
      val = attributes.with_indifferent_access[attr]
      arel_attr = self.class.arel_table[attr.to_sym]
      self.class.where(arel_attr.matches(val))
    end

    def where_potential_duplicate_whitespace(attr)
      val = attributes.with_indifferent_access[attr]
      return self.class.none unless fuzzy_string_value?(val)

      val_sans_whitespace = val.gsub(/\s/, '%')

      arel_attr = self.class.arel_table[attr.to_sym]
      self.class.where(arel_attr.matches(val_sans_whitespace))
    end

    def where_potential_duplicate_mojibake(attr)
      val = attributes.with_indifferent_access[attr]
      return self.class.none unless fuzzy_string_value?(val)

      val_sans_nonascii = val.gsub(/[[:^ascii:]]/, '%')

      arel_attr = self.class.arel_table[attr.to_sym]
      self.class.where(arel_attr.matches(val_sans_nonascii))
    end

    private

    def fuzzy_string_value?(val)
      val.is_a?(String) && val.present?
    end
  end
end
