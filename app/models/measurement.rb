class Measurement < ApplicationRecord

  has_paper_trail

  belongs_to :sample
  
  belongs_to :lab, optional: true
  accepts_nested_attributes_for :lab, reject_if: :all_blank
  validates_associated :lab

  belongs_to :measurement_state, optional: true
  accepts_nested_attributes_for :measurement_state, reject_if: :all_blank
  validates_associated :measurement_state

  belongs_to :c14_measurement, optional: true
  accepts_nested_attributes_for :c14_measurement, reject_if: :all_blank
  validates_associated :c14_measurement

  has_and_belongs_to_many :references, optional: true
  accepts_nested_attributes_for :references, reject_if: :all_blank
  validates_associated :references

  belongs_to :replacement_measurement,
    class_name: 'Measurement',
    foreign_key: :replaced_by,
    primary_key: :id,
    optional: true

  has_many :replaced_measurements,
    class_name: 'Measurement',
    foreign_key: :replaced_by,
    primary_key: :id

  def replacing=(replacing_ids)
    self.replaced_measurements ||= Measurement.find_by_id(replacing_ids)
  end

  def replacing
    @replacing || Measurement.where(replaced_by: self.id)
  end

  def type
    case
    when defined?(c14_measurement)
      "<sup>14</sup>C Measurement".html_safe
    else
      "undefined"
    end
  end
  
  def temporal_information
    case type
    when "<sup>14</sup>C Measurement"
    ret_val = []
    ret_val[0] = c14_measurement.uncalibrated_to_setence unless c14_measurement.uncalibrated_to_setence.blank?
    ret_val[1] = c14_measurement.calibrated_to_setence unless c14_measurement.calibrated_to_setence.blank?
    ret_val.join("<br>").html_safe
      
    else
      "undefined"
    end
  end
  
  def source_database
    case type
    when "<sup>14</sup>C Measurement"
	  c14_measurement.source_database      
    else
      "undefined"
    end
  end

  def self.to_csv
    CSV.generate :force_quotes=>true do |csv|
      csv << [
        "source_database",
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
      all.each do |record|
        csv << [record.c14_measurement.source_database&.name] +
          [record.labnr] +
          [record.c14_measurement.bp] +
          [record.c14_measurement.std] +
          [record.c14_measurement.cal_bp] +
          [record.c14_measurement.cal_std] +
          [record.c14_measurement.delta_c13] +
          [record.lab&.name] +
          [record.sample.arch_object.site_phase.site.name] +
          [record.sample.arch_object.site_phase.name] +
          [record.sample.arch_object.site_phase.site_type&.name] +
          [record.sample.arch_object.on_site_object_position.feature] +
          [record.sample.arch_object.on_site_object_position.feature_type&.name] +
          [record.sample.arch_object.site_phase.periods.map(&:name).join(" | ")] +
          [record.sample.arch_object.site_phase.typochronological_units.map(&:name).join(" | ")] +
          [record.sample.arch_object.site_phase.ecochronological_units.map(&:name).join(" | ")] +
          [record.sample.arch_object.material&.name] +
          [record.sample.arch_object.species&.name] +
          [record.sample.arch_object.site_phase.site.country&.name] +
          [record.sample.arch_object.site_phase.site.lat] +
          [record.sample.arch_object.site_phase.site.lng] +
          [record.references.map(&:short_ref).join(" | ")]
      end
    end
  end

end

