json.set! :data do
  json.array! @source_databases do |source_database|
    json.partial! 'source_databases/source_database', source_database: source_database
    json.url  "
              #{link_to 'Show', source_database }
              #{link_to 'Edit', edit_source_database_path(source_database)}
              #{link_to 'Destroy', source_database, method: :delete, data: { confirm: 'Are you sure?' }}
              "
  end
end