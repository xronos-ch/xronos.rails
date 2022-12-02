json.extract! measurement, :id, :labnr, :sample_id, :lab_id, :created_at, :updated_at

json.lab measurement.lab, partial: 'labs/lab', as: :lab

json.c14_measurement measurement.c14_measurement, partial: 'c14_measurements/c14_measurement', as: :c14_measurement

json.references measurement.references, partial: 'references/reference', as: :reference

json.sample do
  json.partial! "/samples/sample", sample: measurement.sample
end

json.url measurement_url(measurement, format: :json)
