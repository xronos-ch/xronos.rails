json.extract! site, :id, :name, :lat, :lng, :created_at, :updated_at
json.url site_url(site, format: :json)
