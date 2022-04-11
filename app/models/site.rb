class Site < ApplicationRecord
  include DataHelper

  has_paper_trail
  
  validates :name, presence: true

  has_many :contexts, inverse_of: :site

  has_and_belongs_to_many :site_types, optional: true

  belongs_to :country, optional: true
  accepts_nested_attributes_for :country, reject_if: :all_blank, allow_destroy: true
  validates_associated :country

  has_many :c14s, through: :contexts
  has_many :typos, through: :contexts

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
