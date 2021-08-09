json.extract! period, :id, :name, :approx_start_time, :approx_end_time, :created_at, :updated_at

json.site_phases period.site_phases do |site_phase|
    json.(site_phase, :id)
end

json.url period_url(period, format: :json)
