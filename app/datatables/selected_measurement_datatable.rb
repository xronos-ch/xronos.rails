class SelectedMeasurementDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

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
      edit: { source: "ArchObject.id" },
      labnr: { source: "Measurement.labnr", cond: :like },
      year: { source: "Measurement.year", cond: :like },
      site: { source: "Site.name", cond: :like },
      site_type: { source: "SiteType.name", cond: :like },
      lat: { source: "Site.lat", cond: :like },
      lng: { source: "Site.lng", cond: :like },
      country: { source: "Country.name", cond: :like },
      feature: { source: "OnSiteObjectPosition.feature", cond: :like },
      material: { source: "Material.name", cond: :like },
      species: { source: "Measurement.species", cond: :like }
    }
  end

  def data
    Rails.logger.debug records.first.to_yaml
    records.map do |record|
      {
        "edit": link_to("edit", edit_arch_object_path(record.arch_object_id)),
        "labnr": best_in_place(Measurement.find(record.measurement_id), :labnr),
        "year": best_in_place(Measurement.find(record.measurement_id), :year),
        "site": best_in_place(Site.find(record.site_id), :name),
        "site_type": best_in_place(SiteType.find(record.site_type_id), :name),
        "lat": best_in_place(Site.find(record.site_id), :lat),
        "lng": best_in_place(Site.find(record.site_id), :lng),
        "country": best_in_place(Country.find(record.country_id), :name),
        "feature": best_in_place(OnSiteObjectPosition.find(record.on_site_object_position_id), :feature),
        "material": best_in_place(Material.find(record.material_id), :name),
        "species": best_in_place(Species.find(record.species_id), :name)
      }
    end
  end

  def get_raw_records
    return options[:selected_measurements]
  end

end
