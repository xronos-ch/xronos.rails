class SelectedMeasurementDatatable < AjaxDatatablesRails::ActiveRecord

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      measurements_id: { source: "Measurement.id", cond: :like },
      measurements_labnr: { source: "Measurement.labnr", cond: :like },
      measurements_year: { source: "Measurement.year", cond: :like },
      #site_name: { source: "Site.name", cond: :like },
      #site_lat: { source: "Site.lat", cond: :like },
      #site_lng: { source: "Site.lng", cond: :like }
    }
  end

  def data
    records.map do |record|
      {
        "measurements_id": record.id,
        "measurements_labnr": record.labnr,
        "measurements_year": record.year
        #measurement.site.name,
        #measurement.site.lat,
        #measurement.site.lng
      }
    end
  end

  def get_raw_records
    Measurement.all#.joins(
      #sample: {arch_object: :site}
    #).all
  end

end
