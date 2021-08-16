json.extract! arch_object, :id, :created_at, :updated_at

json.material arch_object.material, partial: 'materials/material', as: :material
json.species arch_object.species, partial: 'species/species', as: :species

json.on_site_object_position arch_object.on_site_object_position, partial: "on_site_object_positions/on_site_object_position", as: :on_site_object_position

json.site_phase arch_object.site_phase, partial: 'site_phases/site_phase', as: :site_phase

json.samples arch_object.samples do |sample|
    json.(sample, :id)
end

json.url arch_object_url(arch_object, format: :json)
