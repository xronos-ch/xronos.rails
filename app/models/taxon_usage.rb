##
# Represents a taxonomic usage according to the GBIF Backbone Taxonomy API:
#   <https://www.gbif.org/developer/species>
class TaxonUsage
  include ActiveModel::Conversion
  include ActiveModel::Model
  extend ActiveModel::Naming

  attr_accessor :id

  def gbif
    Rails.cache.fetch("gbif_usage/response/#{id}", expires_in: 30.days) do
      Rails.logger.debug "GBIF API request: #{api_url}"
      Gbif::Request.new("species/#{id}", nil, nil, nil).perform
    end
  end

  def url
    "https://www.gbif.org/species/#{@id}"
  end

  def api_url
    "https://api.gbif.org/v1/species/#{@id}"
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
