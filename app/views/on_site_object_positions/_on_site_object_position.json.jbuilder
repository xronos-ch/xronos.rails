json.extract! on_site_object_position, :id, :feature, :site_grid_square, :coord_reference_system, :coord_X, :coord_Y, :coord_Z, :created_at, :updated_at

json.feature_type on_site_object_position.feature_type, partial: 'feature_types/feature_type', as: :feature_type

json.arch_objects on_site_object_position.arch_objects do |arch_object|
    json.(arch_object, :id)
end

json.url on_site_object_position_url(on_site_object_position, format: :json)
