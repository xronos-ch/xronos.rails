json.extract! taxon, :id, :name, :gbif_id, :created_at, :updated_at
json.url taxon_url(taxon, format: :json)
