json.extract! fell_phase, :id, :name, :start_time, :end_time, :site_id, :created_at, :updated_at

json.site fell_phase.site, partial: 'sites/site', as: :site

json.references fell_phase.references do |reference|
    json.(reference, :id)
end

json.url fell_phase_url(fell_phase, format: :json)
