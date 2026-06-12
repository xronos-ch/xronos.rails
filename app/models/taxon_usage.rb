##
# Represents a taxonomic usage according to the GBIF Backbone Taxonomy API:
#   <https://www.gbif.org/developer/species>
class TaxonUsage
  include ActiveModel::Conversion
  include ActiveModel::Model
  extend ActiveModel::Naming

  attr_accessor :id

  def gbif
    return @gbif if defined?(@gbif)

    result = GBIF::Species.usage(id)

    @failed = result.nil?
    @gbif = result || {}
  end

  def failed?
    gbif
    @failed
  end

  def present?
    canonical_name.present?
  end

  def url
    TaxonUsage.url @id
  end

  def api_url
    TaxonUsage.api_url @id
  end

  def self.url(id)
    "https://www.gbif.org/species/#{id}"
  end

  def self.api_url(id)
    "https://api.gbif.org/v1/species/#{id}"
  end

  def rank
    gbif.fetch("rank", nil)
  end

  def canonical_name
    gbif.fetch("canonicalName", nil)
  end

  def authorship
    gbif.fetch("authorship", nil)
  end

end
