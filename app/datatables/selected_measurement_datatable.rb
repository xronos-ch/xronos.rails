class SelectedMeasurementDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  def_delegators :@view, :link_to, :calibrate_c14_measurement_path
  def_delegators :@view, :link_to, :edit_arch_object_path
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
      edit: { source: "ArchObject.id" },
      calibrate: { source: "C14Measurement.id" },
      labnr: { source: "Measurement.labnr", cond: :like },
      bp: { source: "C14Measurement.bp", cond: :like },
      std: { source: "C14Measurement.std", cond: :like },
      cal_bp: { source: "C14Measurement.cal_bp", cond: :like },
      cal_std: { source: "C14Measurement.cal_std", cond: :like },
      delta_c13: { source: "C14Measurement.delta_c13", cond: :like },
      site: { source: "Site.name", cond: :like },
      site_type: { source: "SiteType.name", cond: :like },
      feature: { source: "OnSiteObjectPosition.feature", cond: :like },
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
        "select": "",
        "edit": link_to("edit", edit_arch_object_path(record.arch_object_id)),
        "calibrate": link_to("calibrate", calibrate_c14_measurement_path(record.c14_measurement_id)),
        "labnr": best_in_place(Measurement.find(record.measurement_id), :labnr),
        "bp": best_in_place(C14Measurement.find(record.c14_measurement_id), :bp),
        "std": best_in_place(C14Measurement.find(record.c14_measurement_id), :std),
        "cal_bp": best_in_place(C14Measurement.find(record.c14_measurement_id), :cal_bp),
        "cal_std": best_in_place(C14Measurement.find(record.c14_measurement_id), :cal_std),
        "delta_c13": best_in_place(C14Measurement.find(record.c14_measurement_id), :delta_c13),
        "site": best_in_place(Site.find(record.site_id), :name),
        "site_type": best_in_place(SiteType.find(record.site_type_id), :name),
        "feature": best_in_place(OnSiteObjectPosition.find(record.on_site_object_position_id), :feature),
        "period": record.periods_names, #Period.where(:id => record.period_id).pluck(:name).join(', '),
        "typochronological_unit": record.typochronological_units_names,
        "ecochronological_unit": record.ecochronological_units_names,
        "material": best_in_place(Material.find(record.material_id), :name),
        "species": best_in_place(Species.find(record.species_id), :name),
        "country": best_in_place(Country.find(record.country_id), :name),
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
