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


  validates :name, presence: true

  has_many :contexts, inverse_of: :site

  has_and_belongs_to_many :site_types, optional: true

  has_many :c14s, through: :contexts
  has_many :typos, through: :contexts

  has_many :citations, as: :citing
  has_many :references, through: :citations

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
    result = Geocoder.search([lat, lng])
    ISO3166::Country[result.first.country_code]
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

  def recursive_references
    c14_references = c14s.map(&:references).reduce(:+)
    unless c14_references.nil?
      (references + c14_references).uniq
    else
      references
    end
  end

end
