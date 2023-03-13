# == Schema Information
#
# Table name: sites
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
  include DataHelper

  include Versioned
  include Supersedable
  include Duplicable
  duplicable :name, :lat, :lng, :country_code

  include PgSearch::Model
  pg_search_scope :search, 
    against: :name, 
    using: { tsearch: { prefix: true } } # match partial words
  multisearchable against: :name

  has_paper_trail
  acts_as_copy_target # enable CSV exports
  
  validates :name, presence: true

  has_and_belongs_to_many :site_types, optional: true

  has_many :contexts
  has_many :samples, through: :contexts
  has_many :c14s, through: :contexts
  has_many :typos, through: :contexts

  has_many :citations, as: :citing
  has_many :references, through: :citations

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
    if result.country_code.present?
      return ISO3166::Country[result.country_code]
    else
      return nil
    end
  end

  def coordinates(format = "dd")
    return nil if lat.blank? || lng.blank?

    y = lat < 0 ? "S" : "N"
    x = lng < 0 ? "W" : "E"

    case format
    when "dd"
      "#{'%07.3f' % lat.abs}° #{y}, #{'%07.3f' % lng.abs}° #{x}"
    when "dms"
      ydeg = lat.abs.floor
      ymin = (lat.abs % 1 * 60).floor
      ysec = (ymin % 1 * 60).round
      xdeg = lng.abs.floor
      xmin = (lng.abs % 1 * 60).floor
      xsec = (xmin % 1 * 60).round
      "#{'%03d' % ydeg}° #{'%02d' % ymin}\' #{'%02d' % ysec}\" #{y}" +
        ", " +
        "#{'%03d' % xdeg}° #{'%02d' % xmin}\' #{'%02d' % xsec}\" #{x}"
    end
  end

  def n_c14s
    c14s.count
  end

  def n_typos
    typos.count
  end

  def recursive_references
    c14_references = c14s.map(&:references).reduce(:+)
    unless c14_references.nil?
      (references + c14_references).uniq
    else
      references
    end
  end

end
