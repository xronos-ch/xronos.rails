json.extract! site_phase, :id, :name, :approx_start_time, :approx_end_time, :created_at, :updated_at

json.site_type site_phase.site_type, partial: 'site_types/site_type', as: :site_type

json.arch_objects site_phase.arch_objects do |arch_object|
    json.(arch_object, :id)
end

json.periods site_phase.periods do |period|
    json.(period, :id)
end

json.typochronological_units site_phase.typochronological_units do |typochronological_unit|
    json.(typochronological_unit, :id)
end

json.ecochronological_units site_phase.ecochronological_units do |ecochronological_unit|
    json.(ecochronological_unit, :id)
end

json.url site_phase_url(site_phase, format: :json)
