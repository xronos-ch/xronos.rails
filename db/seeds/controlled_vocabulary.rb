# Populate the controlled_vocabularies from the OBO source files
# configured in db/data/sources.rb. Auto-loaded by db:seed (via the
# existing Dir glob in db/seeds.rb) and re-runnable any time via:
#
#   bin/rails runner db/seeds/controlled_vocabulary.rb
#
# Idempotent: re-running produces no further changes after the first
# run, because the operation is fully derived from the source files.

require Rails.root.join('db/data/sources')

UBERON_FILTER = ->(term) {
  return false if term[:is_obsolete]
  return false unless (term[:subsets] & %w[organ_slim uberon_slim]).any?
  return false if (term[:subsets] & %w[grouping_class non_informative upper_level]).any?
  return false if ['multicellular organism', 'whole organism'].include?(term[:name].to_s)

  true
}.freeze

PO_FILTER = ->(term) {
  return false if term[:is_obsolete]
  return false unless term[:namespace] == 'plant_anatomy'

  true
}.freeze

FILTERS = { 'uberon' => UBERON_FILTER, 'po' => PO_FILTER }.freeze

puts "Seeding controlled vocabularies from #{SOURCES.length} sources..."
  
SOURCES.each do |source|
  filter   = FILTERS.fetch(source[:source_key])
  obo_path = Rails.root.join(source[:path])
  ontology = source[:source_key].upcase
  kept     = Obo::Parser.each_term(obo_path).select { |t| filter.call(t) }
  kept_ids = kept.map { |t| t[:id] }

  vocabulary = ControlledVocabulary.find_or_create_by!(name: source[:vocabulary])

  ActiveRecord::Base.transaction do
    existing = vocabulary.terms.where(ontology_name: ontology).to_a
    existing_by_oid = existing.index_by(&:ontology_id)
    existing.reject { |t| kept_ids.include?(t.ontology_id) }.each(&:destroy!)

    kept.each do |t|
      record = existing_by_oid[t[:id]] ||
               vocabulary.terms.build(ontology_name: ontology, ontology_id: t[:id])
      record.name        = t[:name]
      record.description = t[:definition]
      record.save!

      record.variants.destroy_all
      Obo::Parser.variant_values_for(t).each do |value|
        record.variants.create!(value: value)
      end
    end
  end

  puts "  #{source[:vocabulary]}/#{source[:source_key]}: seeded #{kept.size} terms"
end
