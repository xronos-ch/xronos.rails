class SelectedMeasurementDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  def_delegators :@view, :link_to, :lab_path
  def_delegators :@view, :link_to, :site_path
  def_delegators :@view, :link_to, :site_phase_path
  def_delegators :@view, :link_to, :site_type_path
  def_delegators :@view, :link_to, :feature_type_path
  def_delegators :@view, :best_in_place

  def initialize(params, opts = {})
    @view = opts[:view_context]
    super
  end

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      select: { source: "Measurement.id" },
      labnr: { source: "Measurement.labnr", cond: :like },
      bp: { source: "C14Measurement.bp", cond: :like },
      std: { source: "C14Measurement.std", cond: :like },
      cal_bp: { source: "C14Measurement.cal_bp", cond: :like },
      cal_std: { source: "C14Measurement.cal_std", cond: :like },
      delta_c13: { source: "C14Measurement.delta_c13", cond: :like },
      lab_name: { source: "Lab.name", cond: :like },
      site: { source: "Site.name", cond: :like },
      site_phase: { source: "SitePhase.name", cond: :like },
      site_type: { source: "SiteType.name", cond: :like },
      feature: { source: "OnSiteObjectPosition.feature", cond: :like },
      feature_type: { source: "FeatureType.name", cond: :like },
      period: { source: "Period.name", cond: :like },
      typochronological_unit: { source: "TypochronologicalUnit.name", cond: :like },
      ecochronological_unit: { source: "EcochronologicalUnit.name", cond: :like },
      material: { source: "Material.name", cond: :like },
      species: { source: "Measurement.species", cond: :like },
      country: { source: "Country.name", cond: :like },
      lat: { source: "Site.lat", cond: :like },
      lng: { source: "Site.lng", cond: :like },
      short_ref: { source: "Reference.short_ref", cond: :like }
    }
  end

  def data
    ## following still might cause trouble when relationships are NIL
    records.map do |record|
      {
        "arch_object_id": record.sample.arch_object.id,
        "measurement_id": record.id,
        "c14_measurement_id": record.c14_measurement_id,
        "select": "",
        "labnr": best_in_place(Measurement.find(record.id), :labnr),
        "bp": best_in_place(C14Measurement.find(record.c14_measurement.id), :bp),
        "std": best_in_place(C14Measurement.find(record.c14_measurement.id), :std),
        "cal_bp": best_in_place(C14Measurement.find(record.c14_measurement.id), :cal_bp),
        "cal_std": best_in_place(C14Measurement.find(record.c14_measurement.id), :cal_std),
        "delta_c13": best_in_place(C14Measurement.find(record.c14_measurement.id), :delta_c13),
        "lab_name": record.lab&.name || "",#link_to(record.lab_name, lab_path(record.lab_id)),
        "site_phase": record.sample.arch_object.site_phase.present? ? link_to(record.sample.arch_object.site_phase.name, site_phase_path(record.sample.arch_object.site_phase.id)) : '',
				"site": record.sample.arch_object.site_phase.present? && record.sample.arch_object.site_phase.site.present? ? link_to(record.sample.arch_object.site_phase.site.name, site_path(record.sample.arch_object.site_phase.site.id)) : '',
        "site_type": record.sample.arch_object.site_phase.present? && record.sample.arch_object.site_phase.site_type.present? ? link_to(record.sample.arch_object.site_phase.site_type.name, site_type_path(record.sample.arch_object.site_phase.site_type.id)) : '',
        "feature": record.sample.arch_object.on_site_object_position_id.present? ? best_in_place(OnSiteObjectPosition.find(record.sample.arch_object&.on_site_object_position&.id), :feature) : record.sample.arch_object.on_site_object_position_id.to_s,
        "feature_type": record.sample.arch_object.on_site_object_position_id.present? ? record.sample.arch_object.on_site_object_position.feature_type&.name : record.sample.arch_object.on_site_object_position_id.to_s,
        "period": record.sample.arch_object.site_phase.present? && record.sample.arch_object.site_phase.periods.present? ? record.sample.arch_object.site_phase.periods.map(&:name).join(",") : '',
        "typochronological_unit": record.sample.arch_object.site_phase.present? && record.sample.arch_object.site_phase.typochronological_units.present? ? record.sample.arch_object.site_phase.typochronological_units.map(&:name).join(",") : '',
        "ecochronological_unit": record.sample.arch_object.site_phase.present? && record.sample.arch_object.site_phase.ecochronological_units.present? ? record.sample.arch_object.site_phase.ecochronological_units.map(&:name).join(",") : '',
        "material": record.sample.arch_object.material&.name,
        "species": record.sample.arch_object.species&.name,
        "country": record.sample.arch_object.site_phase.present? && record.sample.arch_object.site_phase.site.present? && record.sample.arch_object.site_phase.site.country.present? ? record.sample.arch_object.site_phase.site.country.name : '',
        "lat": record.sample.arch_object.site_phase.present? && record.sample.arch_object.site_phase.site.present? && record.sample.arch_object.site_phase.site.lat.present? ? best_in_place(Site.find(record.sample.arch_object.site_phase.site.id), :lat) : '',
        "lng": record.sample.arch_object.site_phase.present? && record.sample.arch_object.site_phase.site.present? && record.sample.arch_object.site_phase.site.lng.present? ? best_in_place(Site.find(record.sample.arch_object.site_phase.site.id), :lng) : '',
        "short_ref": record.references.map(&:short_ref).join(",")
      }
    end
  end

  def get_raw_records
    return options[:selected_measurements]
  end

end
