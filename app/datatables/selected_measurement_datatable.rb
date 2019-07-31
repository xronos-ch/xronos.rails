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
        "labnr": record.labnr,
        "year": best_in_place(Measurement.find(record.measurement_id), :year),
        "site": record.site,
        "site_type": record.site_type,
        "lat": record.lat,
        "lng": record.lng,
        "country": record.country,
        "feature": record.feature,
        "material": record.material,
        "species": record.species
      }
    end
  end

  def get_raw_records
    return options[:selected_measurements]
  end

end
