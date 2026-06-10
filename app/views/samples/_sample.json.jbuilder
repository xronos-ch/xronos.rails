json.extract! sample,
              :id,
              :material_id,
              :taxon_id,
              :context_id,
              :position_description,
              :position_x,
              :position_y,
              :position_z,
              :position_crs,
              :created_at,
              :updated_at

json.material sample.material&.name
json.taxon sample.taxon&.name

json.context do
  if sample.context.present?
    json.id sample.context.id
    json.name sample.context.name
    json.url context_url(sample.context, format: :json)
  else
    json.nil!
  end
end

json.url sample_url(sample, format: :json)