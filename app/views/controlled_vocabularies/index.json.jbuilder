json.array! @results do |result|
  json.extract! result.term, :name, :ontology_name, :ontology_id
  json.url result.term.ontology_url
  json.description result.term.description_excerpt
  json.match result.match
  json.matched_variant result.matched_variant if result.match == "variant"
end
