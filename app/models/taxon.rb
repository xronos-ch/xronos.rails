# == Schema Information
#
# Table name: taxons
# Database name: primary
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  gbif_id    :integer
#
# Indexes
#
#  index_taxons_on_gbif_id  (gbif_id)
#  index_taxons_on_name     (name)
#

class Taxon < ApplicationRecord
  include Versioned

  has_many :samples

  validates :name, presence: true

  after_commit :enqueue_gbif_sync

  include HasIssues
  @issues = [ :unknown_taxon, :long_taxon ]

  include PgSearch::Model
  pg_search_scope :search, 
    against: :name, 
    using: { tsearch: { prefix: true } } # match partial words

  acts_as_copy_target # enable CSV exports

  validates :name, presence: true

  has_many :samples

  scope :with_samples_count, -> {
    select <<~SQL
      "taxons".*,
      (
        SELECT COUNT(samples.id) 
        FROM samples
        WHERE taxon_id = taxons.id
      ) AS samples_count
    SQL
  }

  def usage
    return nil if gbif_id.blank?
    TaxonUsage.new(id: gbif_id)
  end

  def gbif_id?
    gbif_id.present?
  end

  def enqueue_gbif_sync
    return if name.blank? and gbif_id.blank?
    SyncTaxonWithGbifJob.perform_later(id)
  end

  def self.label
    "taxon"
  end

  def self.search_with_gbif(query, limit: 5, matched_only: false)
    return [] if query.blank?

    local_taxons = search(query)

    if matched_only
      # Use database index if available
      if local_taxons.respond_to?(:where)
        local_taxons = local_taxons.where.not(gbif_id: :nil)
      else
        local_taxons = local_taxons.select { |t| t.gbif_id.present? }
      end
    end

    local_taxons = local_taxons.limit(limit) if local_taxons.respond_to?(:limit)

    gbif_results = GBIF::Species.search(query: query, limit: limit)
    gbif_taxons  = build_from_gbif_response(gbif_results)

    unique_taxons(local_taxons + gbif_taxons)
  end

  def self.from_gbif_result(result)
    new(
      name: result["canonicalName"],
      gbif_id: result["acceptedKey"] || result["key"]
    )
  end

  # Tidy up unused taxa when samples are deleted
  def destroy_if_orphaned
    if samples.count == 0
      self.destroy
    end
  end

  # Issues

  scope :unknown_taxon, -> { where(gbif_id: nil) }
  def unknown_taxon?
    not gbif_id?
  end

  scope :long_taxon, -> { where("LENGTH(name) > 64") }
  def long_taxon?
    return nil if name.blank?
    name.length > 64
  end

  private_class_method

  # Extract Taxons from a GBIF search response
  def self.build_from_gbif_response(response)
    response
      &.fetch("results", [])
      &.map { |r| from_gbif_result(r) } || []
  end

  # Deduplicate by gbif_id if present, otherwise by name
  def self.unique_taxons(taxons)
    taxons.uniq { |t| t.gbif_id.presence || t.name }
  end

end
