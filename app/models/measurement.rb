class Measurement < ApplicationRecord
  belongs_to :sample
  belongs_to :lab, optional: true
  validates_associated :lab
  belongs_to :c14_measurement, optional: true
  accepts_nested_attributes_for :c14_measurement, reject_if: :all_blank
  validates_associated :c14_measurement

  has_many :references_measurements
  has_many :references, through: :references_measurements
  accepts_nested_attributes_for :references_measurements, reject_if: :all_blank
  validates_associated :references_measurements

  def self.to_csv
    CSV.generate do |csv|
      csv << ["labnr", "site", "site_type", "lat", "lng", "country", "feature", "material", "species"]
      all.each do |item|
        csv << [item.labnr] + [item.site] + [item.site_type] +
            [item.lat] + [item.lng] + [item.country] + [item.feature] +
            [item.material] + [item.species]
      end
    end
  end

end
