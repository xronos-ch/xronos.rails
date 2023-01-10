json.extract! taxon, :id, :name, :created_at, :updated_at
json.url taxon_url(taxon, format: :json)
