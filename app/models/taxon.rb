# == Schema Information
#
# Table name: taxons
#
#  id            :bigint           not null, primary key
#  name          :string
#  superseded_by :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  gbif_id       :integer
#
# Indexes
#
#  index_taxons_on_gbif_id        (gbif_id)
#  index_taxons_on_name           (name)
#  index_taxons_on_superseded_by  (superseded_by)
#
class Taxon < ApplicationRecord

  has_many :samples

  validates :name, presence: true

  include Versioned

  include Controlled

  def controlled?
    gbif_id.present?
  end

  scope :uncontrolled, -> { where(gbif_id: nil) }

  has_one :unknown_taxon, class_name: 'Issues::UnknownTaxon'

  before_save :control, unless: :controlled?

  include PgSearch::Model
  pg_search_scope :search, 
    against: :name, 
    using: { tsearch: { prefix: true } } # match partial words

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

  def gbif_usage
    if gbif_id.blank?
      return nil
    end

    Rails.cache.fetch("#{cache_key_with_version}/gbif_usage", expires_in: 24.hours) do
      logger.debug "GBIF API request: https://api.gbif.org/v1/species/#{gbif_id}"
      resp = Gbif::Request.new("species/#{gbif_id}", nil, nil, nil).perform
      # TODO: recover from server errors?
      OpenStruct.new(resp)
    end
  end

  def gbif_match(strict = false)
    Rails.cache.fetch("#{cache_key_with_version}/gbif_match", expires_in: 24.hours) do
      logger.debug "GBIF API request: https://api.gbif.org/v1/species/match?name=#{name}"
      OpenStruct.new(Gbif::Species.name_backbone(name: name, strict: strict))
    end
  end

  def set_attributes_from_gbif_match(strict = true)
    gbif = gbif_match(strict = strict)
    fuzzy_matches = ["AGGREGATE", "FUZZY", "HIGHERRANK"]
    if gbif.matchType == "EXACT" or (!strict and gbif.matchType.in?(fuzzy_matches))
      self.name = gbif.canonicalName
      self.gbif_id = gbif.usageKey
      self.revision_comment = "Matched to GBIF Backbone Taxonomy"
      return gbif
    end
  end

  private

  def control
    return if skip_control
    set_attributes_from_gbif_match
  end
end
