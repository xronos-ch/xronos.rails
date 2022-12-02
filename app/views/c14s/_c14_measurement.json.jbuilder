json.extract! c14_measurement, :id, :bp, :std, :cal_bp, :cal_std, :delta_c13, :delta_c13_std, :method, :created_at, :updated_at

json.measurement [id: c14_measurement.measurement.id]

json.url c14_measurement_url(c14_measurement, format: :json)
