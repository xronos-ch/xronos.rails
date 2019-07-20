json.set! :data do
  json.array! @ecochronological_units do |ecochronological_unit|
    json.partial! 'ecochronological_units/ecochronological_unit', ecochronological_unit: ecochronological_unit
    json.url  "
              #{link_to 'Show', ecochronological_unit }
              #{link_to 'Edit', edit_ecochronological_unit_path(ecochronological_unit)}
              #{link_to 'Destroy', ecochronological_unit, method: :delete, data: { confirm: 'Are you sure?' }}
              "
  end
end