json.extract! source_database, :id, :name, :url, :citation, :licence, :created_at, :updated_at
json.url source_database_url(source_database, format: :json)
