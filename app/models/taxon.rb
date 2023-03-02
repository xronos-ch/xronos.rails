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
  include Versioned

  include PgSearch::Model
  pg_search_scope :search, 
    against: :name, 
    using: { tsearch: { prefix: true } } # match partial words

  validates :name, presence: true

  has_many :samples

  def gbif_usage
    if gbif_id.blank?
      return nil
    end
    resp = Gbif::Request.new("species/#{gbif_id}", nil, nil, nil).perform
    # TODO: recover from server errors?
    OpenStruct.new(resp)
  end

  def gbif_match(strict = false)
    OpenStruct.new(Gbif::Species.name_backbone(name: name, strict: strict))
  end

  def update_from_gbif_match(strict = true)
    gbif = gbif_match(strict = strict)
    if gbif.matchType == "EXACT" or !strict and gbif.matchType == "FUZZY"
      self.name = gbif.canonicalName
      self.gbif_id = gbif.usageKey
      self.revision_comment = "Matched to GBIF Backbone Taxonomy"
      self.save!
    end
  end
end
