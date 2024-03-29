# == Schema Information
#
# Table name: taxons
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

  include Versioned

  before_save :set_gbif_id_from_match, unless: :gbif_id?
  before_save :set_name_from_usage

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

  def gbif_match(strict = false)
    Rails.cache.fetch("gbif_match/#{name}", expires_in: 24.hours) do
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

  def gbif_usage_from_match(match = gbif_match)
    TaxonUsage.new(id: gbif_id_from_match(match))
  end

  def set_gbif_id_from_match(strict = true)
    match = gbif_match(strict = strict)
    fuzzy_matches = ["AGGREGATE", "FUZZY", "HIGHERRANK"]
    if match.matchType == "EXACT" or (!strict and match.matchType.in?(fuzzy_matches))
      self.gbif_id = gbif_id_from_match(match)
    else
      self.gbif_id = nil
    end
  end

  def set_name_from_usage
    self.name = usage.canonical_name unless gbif_id.blank?
  end

  def self.label
    "taxon"
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
