json.extract! ecochronological_unit, :id, :name, :approx_start_time, :approx_end_time, :created_at, :updated_at

json.site_phases ecochronological_unit.site_phases do |site_phase|
    json.(site_phase, :id)
end

json.url ecochronological_unit_url(ecochronological_unit, format: :json)
