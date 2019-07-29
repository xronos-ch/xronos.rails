json.set! :data do
  json.array! @fell_phases do |fell_phase|
    json.partial! 'fell_phases/fell_phase', fell_phase: fell_phase
    json.url  "
              #{link_to 'Show', fell_phase }
              #{link_to 'Edit', edit_fell_phase_path(fell_phase)}
              #{link_to 'Destroy', fell_phase, method: :delete, data: { confirm: 'Are you sure?' }}
              "
  end
end