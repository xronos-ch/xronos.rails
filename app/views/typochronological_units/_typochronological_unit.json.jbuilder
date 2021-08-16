json.extract! typochronological_unit, :id, :name, :approx_start_time, :approx_end_time, :created_at, :updated_at

json.site_phases typochronological_unit.site_phases do |site_phase|
    json.(site_phase, :id)
end

json.url typochronological_unit_url(typochronological_unit, format: :json)
