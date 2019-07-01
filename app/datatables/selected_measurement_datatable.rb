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

  def query_lat_start
    @query_lat_start ||= options[:query_lat_start]
    #puts(@query_lat_start);
  end

  def query_lat_stop
    @query_lat_stop ||= options[:query_lat_stop]
  end

  def get_raw_records
    Measurement.joins(
        sample: {arch_object: [{site: [:site_type, :country]}, {on_site_object_position: :feature_type}, :material, :species]}
    ).select(
      "
      measurements.labnr as labnr,
			measurements.year as year,
      sites.name as site,
      site_types.name as site_type,
      sites.lat as lat,
      sites.lng as lng,
      countries.name as country,
      on_site_object_positions.feature as feature,
      materials.name as material,
      (species.family || ' ' || species.genus || ' ' || species.species  || ' ' || species.subspecies) as species
      "
    ).where(
      "(lat >= ? AND lat <= ?)",
      query_lat_start,
      query_lat_stop
    ).all
  end

end
