class SelectedMeasurementDatatable < AjaxDatatablesRails::ActiveRecord

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
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
    records.map do |record|
      {
        "labnr": record.labnr,
        "year": record.year,
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
    options[:selected_measurements]
  end

end
