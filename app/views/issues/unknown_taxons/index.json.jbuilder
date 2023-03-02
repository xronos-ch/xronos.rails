json.set! :data do
  json.array! @issues_unknown_taxons do |issues_unknown_taxon|
    json.partial! 'issues_unknown_taxons/issues_unknown_taxon', issues_unknown_taxon: issues_unknown_taxon
    json.url  "
              #{link_to 'Show', issues_unknown_taxon }
              #{link_to 'Edit', edit_issues_unknown_taxon_path(issues_unknown_taxon)}
              #{link_to 'Destroy', issues_unknown_taxon, method: :delete, data: { confirm: 'Are you sure?' }}
              "
  end
end