json.extract! dendro, :id, :sample_id, :series_code, :name, :description, :start_year, :end_year, :is_anchored, :offset, :measurements, :created_at, :updated_at
json.url dendro_url(dendro, format: :json)
