class Site < ApplicationRecord
  include DataHelper

  has_paper_trail
  
  validates :name, presence: true

  has_many :contexts, inverse_of: :site

  has_and_belongs_to_many :site_types, optional: true

  has_many :c14s, through: :contexts
  has_many :typos, through: :contexts

  def self.label
    "Site"
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

end
