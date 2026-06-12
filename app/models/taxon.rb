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

  def gbif_match(strict = false)
    Rails.cache.fetch("gbif_match/#{name.parameterize}/#{strict}", 
                      expires_in: 24.hours) do
      logger.debug "GBIF API request: https://api.gbif.org/v1/species/match?name=#{name}"
      OpenStruct.new(Gbif::Species.name_backbone(name: name, strict: strict))
    end
  end

  def gbif_id_from_match(match = gbif_match)
    if match.synonym
      match.acceptedUsageKey
    else
      match.usageKey
    end
  end

  def self.label
    "taxon"
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

end
