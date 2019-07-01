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
      material: { source: "Material.name", cond: :like }
    }
  end

  def data
    records.map do |record|
      {
        "labnr": record.labnr,
        "year": record.year,
        "site": record.sample.arch_object.site.name,
        "site_type": record.sample.arch_object.site.site_type.name,
        "lat": record.sample.arch_object.site.lat,
        "lng": record.sample.arch_object.site.lng,
        "country": record.sample.arch_object.site.country.name,
        "feature": record.sample.arch_object.on_site_object_position.feature,
        "material": record.sample.arch_object.material.name
      }
    end
  end

  def get_raw_records
    Measurement.joins(
      sample: {arch_object: :site}
    ).all
  end

end
