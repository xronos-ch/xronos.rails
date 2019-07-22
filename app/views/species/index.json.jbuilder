json.set! :data do
  json.array! @species do |species|
    json.partial! 'species/species', species: species
    json.url  "
              #{link_to 'Show', species }
              #{link_to 'Edit', edit_species_path(species)}
              #{link_to 'Destroy', species, method: :delete, data: { confirm: 'Are you sure?' }}
              "
  end
end