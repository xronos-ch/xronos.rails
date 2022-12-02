json.set! :data do
  json.array! @c14_measurements do |c14_measurement|
    json.partial! 'c14_measurements/c14_measurement', c14_measurement: c14_measurement
    json.url  "
              #{link_to 'Show', c14_measurement }
              #{link_to 'Edit', edit_c14_measurement_path(c14_measurement)}
              #{link_to 'Destroy', c14_measurement, method: :delete, data: { confirm: 'Are you sure?' }}
              "
  end
end