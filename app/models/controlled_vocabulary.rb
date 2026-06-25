# == Schema Information
#
# Table name: controlled_vocabularies
# Database name: primary
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_controlled_vocabularies_on_name  (name) UNIQUE
#
class ControlledVocabulary < ApplicationRecord
  has_many :terms, class_name: 'ControlledVocabulary::Term', dependent: :destroy
  has_many :variants, through: :terms

  default_scope { order(:name) }

  validates :name, presence: true, uniqueness: true

  def self.[](name) = find_by!(name: name)

  # Result of compute_seed_summary: a count of changes plus the
  # already-filtered terms ready to hand to apply_seed.
  SeedPlan = Struct.new(:summary, :kept_terms, keyword_init: true)

  # Parse the OBO file, apply the filter, and report what would change
  # if the seed were applied. Read-only.
  def self.compute_seed_summary(vocabulary_name:, ontology_name:, obo_path:, filter:)
    kept = Obo::Parser.each_term(obo_path).select { |t| filter.call(t) }
    summary = compute_diff_summary(vocabulary_name: vocabulary_name, ontology_name: ontology_name, terms: kept)
    SeedPlan.new(summary: summary, kept_terms: kept)
  end

  # Re-derive the vocabulary terms from the input: delete terms not in
  # the source, upsert the rest (refreshing name, description, and
  # variants), in a single transaction.
  def self.apply_seed(vocabulary_name:, ontology_name:, terms:)
    parsed = terms.to_a
    kept_ids = parsed.map { |t| t[:id] }
    vocabulary = find_or_create_by!(name: vocabulary_name)

    ActiveRecord::Base.transaction do
      existing = vocabulary.terms.where(ontology_name: ontology_name).to_a
      existing_by_oid = existing.index_by(&:ontology_id)

      existing.reject { |t| kept_ids.include?(t.ontology_id) }.each(&:destroy!)

      parsed.each do |t|
        record = existing_by_oid[t[:id]] ||
                 vocabulary.terms.build(ontology_name: ontology_name, ontology_id: t[:id])
        record.name        = t[:name]
        record.description = t[:definition]
        record.save!

        record.variants.destroy_all
        Obo::Parser.variant_values_for(t).each do |value|
          record.variants.create!(value: value)
        end
      end
    end
  end

  # Selection rules for the part_of_organism vocabulary, per source.
  # The rake task picks one via public_send(:"#{source}_filter").
  def self.uberon_filter
    ->(term) {
      return false if term[:is_obsolete]
      return false unless (term[:subsets] & %w[organ_slim uberon_slim]).any?
      return false if (term[:subsets] & %w[grouping_class non_informative upper_level]).any?
      return false if ['multicellular organism', 'whole organism'].include?(term[:name].to_s)

      true
    }
  end

  def self.po_filter
    ->(term) {
      return false if term[:is_obsolete]
      return false unless term[:subsets].include?('reference')
      return false if term[:id] == 'PO:0000003'

      true
    }
  end

  # Read-only diff of the input against the current DB state. Used by
  # compute_seed_summary.
  def self.compute_diff_summary(vocabulary_name:, ontology_name:, terms:)
    parsed = terms.to_a
    kept_ids = parsed.map { |t| t[:id] }

    existing = ControlledVocabulary::Term
               .joins(:vocabulary)
               .where(controlled_vocabularies: { name: vocabulary_name }, ontology_name: ontology_name)
               .to_a
    existing_by_oid = existing.index_by(&:ontology_id)

    {
      kept:             parsed.size,
      inserted:         parsed.count { |t| !existing_by_oid.key?(t[:id]) },
      updated:          parsed.count { |t|  existing_by_oid.key?(t[:id]) },
      deleted:          existing.count { |t| !kept_ids.include?(t.ontology_id) },
      variants_rebuilt: parsed.sum { |t| Obo::Parser.variant_values_for(t).size }
    }
  end

  private_class_method :compute_diff_summary

  # Exact, case-sensitive name lookup. For fuzzy lookups, use #resolve_variant.
  def match(input)
    terms.find_by(name: input)
  end

  # Case-insensitive lookup against the variant thesaurus. Returns the
  # term whose variant matches the normalised input, or nil.
  def resolve_variant(input)
    return nil if input.blank?

    needle = ControlledVocabulary::Variant.normalize_for_matching(input)
    return nil if needle.empty?

    terms.joins(:variants)
         .find_by(controlled_vocabulary_variants: { normalized: needle })
  end
end
