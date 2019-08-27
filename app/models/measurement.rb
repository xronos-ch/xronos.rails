class Measurement < ApplicationRecord
  belongs_to :sample

  belongs_to :lab, optional: true
  accepts_nested_attributes_for :lab, reject_if: :all_blank, allow_destroy: true
  validates_associated :lab

  belongs_to :c14_measurement, optional: true
  accepts_nested_attributes_for :c14_measurement, reject_if: :all_blank
  validates_associated :c14_measurement

  has_and_belongs_to_many :references
  accepts_nested_attributes_for :references, reject_if: :all_blank
  validates_associated :references

  def self.to_csv
    CSV.generate do |csv|
      csv << [
        "labnr",
        "bp",
        "std",
        "cal_bp",
        "cal_std",
        "delta_c13",
        "lab_name",
        "site",
        "site_phase",
        "site_type",
        "feature",
        "feature_type",
        "periods",
        "typochronological_units",
        "ecochronological_units",
        "material",
        "species",
        "country",
        "lat",
        "lng",
        "references"
      ]
      all.each do |item|
        csv << [item.labnr] +
          [item.bp] +
          [item.std] +
          [item.cal_bp] +
          [item.cal_std] +
          [item.delta_c13] +
          [item.lab_name] +
          [item.site] +
          [item.site_phase] +
          [item.site_type] +
          [item.feature] +
          [item.feature_type] +
          [item.periods_names] +
          [item.typochronological_units_names] +
          [item.ecochronological_units_names] +
          [item.material] +
          [item.species] +
          [item.country] +
          [item.lat] +
          [item.lng] +
          [item.references_short_refs]
      end
    end
  end

end
