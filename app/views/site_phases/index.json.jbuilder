json.set! :data do
  json.array! @site_phases do |site_phase|
    json.partial! 'site_phases/site_phase', site_phase: site_phase
    json.url  "
              #{link_to 'Show', site_phase }
              #{link_to 'Edit', edit_site_phase_path(site_phase)}
              #{link_to 'Destroy', site_phase, method: :delete, data: { confirm: 'Are you sure?' }}
              "
  end
end