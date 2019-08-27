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
    Rails.logger.debug records.first.to_yaml
    records.map do |record|
      {
        "arch_object_id": record.arch_object_id,
        "measurement_id": record.measurement_id,
        "c14_measurement_id": record.c14_measurement_id,
        "select": "",
        "labnr": best_in_place(Measurement.find(record.measurement_id), :labnr),
        "bp": best_in_place(C14Measurement.find(record.c14_measurement_id), :bp),
        "std": best_in_place(C14Measurement.find(record.c14_measurement_id), :std),
        "cal_bp": best_in_place(C14Measurement.find(record.c14_measurement_id), :cal_bp),
        "cal_std": best_in_place(C14Measurement.find(record.c14_measurement_id), :cal_std),
        "delta_c13": best_in_place(C14Measurement.find(record.c14_measurement_id), :delta_c13),
        "lab_name": record.lab_name,#link_to(record.lab_name, lab_path(record.lab_id)),
        "site": link_to(record.site, site_path(record.site_id)),
        "site_phase": link_to(record.site_phase, site_phase_path(record.site_phase_id)),
        "site_type": record.site_type,#link_to(record.site_type, site_type_path(record.site_type_id)),
        "feature": best_in_place(OnSiteObjectPosition.find(record.on_site_object_position_id), :feature),
        "feature_type": record.feature_type,#link_to(record.feature_type, feature_type_path(record.feature_type_id)),
        "period": record.periods_names,
        "typochronological_unit": record.typochronological_units_names,
        "ecochronological_unit": record.ecochronological_units_names,
        "material": record.material,
        "species": record.species,
        "country": record.country,
        "lat": best_in_place(Site.find(record.site_id), :lat),
        "lng": best_in_place(Site.find(record.site_id), :lng),
        "short_ref": record.references_short_refs
      }
    end
  end

  def get_raw_records
    return options[:selected_measurements]
  end

end
