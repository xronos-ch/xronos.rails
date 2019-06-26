class SelectedMeasurementDatatable < AjaxDatatablesRails::ActiveRecord

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      measurements_id: { source: "Measurement.id", cond: :like },
      measurements_labnr: { source: "Measurement.labnr", cond: :like },
      measurements_year: { source: "Measurement.year", cond: :like },
      site_name: { source: "Site.name", cond: :like },
      site_lat: { source: "Site.lat", cond: :like },
      site_lng: { source: "Site.lng", cond: :like }
    }
  end

  def data
    records.map do |record|
      {
        "measurements_id": record.id,
        "measurements_labnr": record.labnr,
        "measurements_year": record.year,
        "site_name": record.sample.arch_object.site.name,
        "site_lat": record.sample.arch_object.site.lat,
        "site_lng": record.sample.arch_object.site.lng
      }
    end
  end

  def get_raw_records
    Measurement.joins(
      sample: {arch_object: :site}
    ).all
  end

end
