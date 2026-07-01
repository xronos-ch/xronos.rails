# == Schema Information
#
# Table name: sites
# Database name: primary
#
#  id            :bigint           not null, primary key
#  country_code  :string
#  lat           :decimal(, )
#  lng           :decimal(, )
#  name          :string
#  superseded_by :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_sites_on_country_code  (country_code)
#  index_sites_on_name          (name)
#

class Site < ApplicationRecord
  include Versioned
  include Supersedable
  include BatchMatchableToWikidata

  # Children
  has_many :site_names, dependent: :destroy
  has_many :contexts
  destroy_async_with_paper_trail :contexts
  has_many :citations, as: :citing, dependent: :destroy_async

  # Grandchildren
  has_many :samples, through: :contexts
  has_many :c14s, through: :contexts
  has_many :typos, through: :contexts
  has_many :references, through: :citations

  # Cousins
  has_and_belongs_to_many :site_types, optional: true

  composed_of :coordinates,
    mapping: [%w(lng longitude), %w(lat latitude)],
    allow_nil: true,
    constructor: ->(lng, lat) do
      # only build Coordinates if we have both values
      if lng.present? && lat.present?
        Coordinates.new(lng, lat)
      else
        nil
      end
    end

  validates :name, presence: true

  accepts_nested_attributes_for :site_names,
    reject_if: :all_blank, allow_destroy: true

  include Duplicable
  duplicable :name, :lat, :lng, :country_code

  acts_as_copy_target # enable CSV exports

  include HasIssues
  @issues = [ :missing_coordinates, :invalid_coordinates, :missing_country_code ]

  include Linkable
  linkable_to :wikidata
  linkable_to :pleiades
  linkable_to :vici
  linkable_to :opencontext
  linkable_to :idai_gazetteer

  include PgSearch::Model
  pg_search_scope :search, 
    against: :name, 
    using: { tsearch: { prefix: true } } # match partial words
  multisearchable against: :name
  
  scope :with_counts, -> {
    select <<~SQL
      sites.*,
      (
        SELECT COUNT(c14s.id) 
        FROM c14s
        JOIN samples ON samples.id = c14s.sample_id
        JOIN contexts ON contexts.id = samples.context_id
        WHERE contexts.site_id = sites.id
      ) AS c14s_count,
      (
        SELECT COUNT(typos.id) 
        FROM typos
        JOIN samples ON samples.id = typos.sample_id
        JOIN contexts ON contexts.id = samples.context_id
        WHERE contexts.site_id = sites.id
      ) AS typos_count
    SQL
  }

  def self.label
    "Site"
  end

  def self.icon
    "icons/site.svg"
  end

  def country
    return nil if country_code.blank?
    ISO3166::Country[country_code] || 
      ISO3166::Country.find_country_by_any_name(country_code)
  end
  
  def country_from_coordinates
    return nil if lat.blank? || lng.blank?

    result = Geocoder.search([lat, lng]).first
    if result && result.country_code.present?
      return ISO3166::Country[result.country_code]
    else
      return nil
    end
  end
  
  def country_code_from_coordinates
    return nil if lat.blank? || lng.blank?

    result = Geocoder.search([lat, lng]).first
    if result && result.country_code.present?
      return result.country_code.upcase
    else
      return nil
    end
  end

  def n_c14s
    c14s.count
  end

  def n_typos
    typos.count
  end

  def recursive_references
    site_reference_scope = Reference
                             .joins(:citations)
                             .where(citations: { citing_type: "Site", citing_id: id })

    c14_reference_scope = Reference
                            .joins(:citations)
                            .where(citations: { citing_type: "C14", citing_id: c14s.select(:id) })

    site_reference_scope.or(c14_reference_scope).distinct.to_a
  end

  def default_c14_curve
    return :IntCal20 unless lat.present?
    # TODO: what about the sea?
    # https://github.com/xronos-ch/xronos.rails/issues/326
    if lat >= 0
      :IntCal20
    else
      :SHCal20
    end
  end

  # Issues
  scope :missing_coordinates, -> { where("lat IS NULL OR lng IS NULL") }
  def missing_coordinates?
    lat.blank? or lng.blank?
  end

  scope :invalid_coordinates, -> { where("lat > 90 OR lat < -90 OR lng > 180 OR lng < -180") }
  def invalid_coordinates?
    unless missing_coordinates?
      coordinates.invalid_latitude? or coordinates.invalid_longitude?
    end
  end

  scope :missing_country_code, -> { where("country_code = '' OR country_code IS NULL") }
  def missing_country_code?
    country_code.blank?
  end
  
end
