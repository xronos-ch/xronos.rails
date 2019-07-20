json.set! :data do
  json.array! @typochronological_units do |typochronological_unit|
    json.partial! 'typochronological_units/typochronological_unit', typochronological_unit: typochronological_unit
    json.url  "
              #{link_to 'Show', typochronological_unit }
              #{link_to 'Edit', edit_typochronological_unit_path(typochronological_unit)}
              #{link_to 'Destroy', typochronological_unit, method: :delete, data: { confirm: 'Are you sure?' }}
              "
  end
end