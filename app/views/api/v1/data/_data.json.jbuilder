json.measurement do
  json.id measurement.id
  json.labnr measurement.lab_identifier.to_s
  json.bp measurement.bp
  json.std measurement.std
  json.cal_bp measurement.cal_bp
  json.cal_std measurement.cal_std
  json.delta_c13 measurement.delta_c13
  json.source_database ""
  json.lab_name(
  (if measurement.c14_lab.blank? then
    ""
  else
    measurement.c14_lab.name
  end))
  json.material measurement.sample.material_name
  json.species measurement.sample.taxon_name
  json.feature measurement.sample.context.name
  json.feature_type("")
  json.site measurement.sample.context.site.name
  json.country measurement.sample.context.site.country_code
  json.lat measurement.sample.context.site.lat
  json.lng measurement.sample.context.site.lng
  json.site_type(
    if measurement.sample.context.site.site_types.empty? then
      ""
    else
      measurement.sample.context.site.site_types.first.name
    end
  )
  json.periods(measurement.sample.context.typos) do |period|
    json.period period.name
  end
  json.typochronological_units(measurement.sample.context.typos) do |typochronological_unit|
    json.typochronological_unit typochronological_unit.name
  end
  json.ecochronological_units([]) do |ecochronological_unit|
    json.ecochronological_unit ecochronological_unit.name
  end
  json.reference measurement.references do |reference|
   json.reference reference.short_ref
  end
end
