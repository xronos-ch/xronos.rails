class SyncTaxonWithGbifJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  def perform(taxon_id)
    taxon = Taxon.find_by(id: taxon_id)
    return unless taxon

    taxon.with_lock do
      sync_taxon!(taxon)
    end
  end

  private

  def sync_taxon!(taxon)
    ensure_gbif_id! taxon
    enforce_canonical_name! taxon
  end

  def ensure_gbif_id!(taxon)
    return if taxon.gbif_id?

    match = GBIF::Species.match(scientificName: taxon.name, strict: true)
    return unless match
    return unless match.dig("diagnostics", "matchType") == "EXACT"

    usage = GBIF::Species.accepted_usage match
    return unless usage.present?

    gbif_id = usage["key"]
    return unless gbif_id.present?

    # Temporarily store usage for reuse in step 2
    taxon.instance_variable_set(:@gbif_match, match)

    # Use update_columns to skip callbacks that would create another job
    taxon.update_columns(gbif_id: gbif_id)
  end

  def enforce_canonical_name!(taxon)
    return unless taxon.gbif_id?

    # Reuse match if available (because it was matched in this job)
    match = taxon.instance_variable_get(:@gbif_match)
    usage = GBIF::Species.accepted_usage(match) || GBIF::Species.usage(taxon.gbif_id)
    return unless usage.present?

    canonical = usage["canonicalName"]
    return if canonical.blank? || canonical == taxon.name

    # Use update_columns to skip callbacks that would create another job
    taxon.update_columns(name: canonical)
  end
end
