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
    return unless taxon.gbif_id?

    match = taxon.gbif_match(strict: false)
    return unless match.matchType == "EXACT"

    # Use update_columns to skip callbacks that would create another job
    taxon.update_columns(gbif_id: taxon.gbif_id_from_match(match))
  end

  def enforce_canonical_name!(taxon)
    return unless taxon.gbif_id?

    canonical = taxon.usage&.canonical_name
    return if canonical.blank? || canonical == taxon.name

    # Use update_columns to skip callbacks that would create another job
    taxon.update_columns(name: canonical)
  end
end
