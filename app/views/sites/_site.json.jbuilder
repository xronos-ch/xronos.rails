json.extract! site, :id, :name, :lat, :lng, :created_at, :updated_at

json.country site.country, partial: 'countries/country', as: :country

json.site_phases site.site_phases do |site_phase|
    json.(site_phase, :id)
end

json.fell_phases site.fell_phases do |fell_phase|
    json.(fell_phase, :id)
end

json.url site_url(site, format: :json)
