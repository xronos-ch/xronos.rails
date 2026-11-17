rank = 0
json.array! @results do |result|
  rank += 1
  json.rank rank
  json.extract! result.term, :name, :ontology_name, :ontology_id
  json.url result.term.ontology_url
  json.description result.term.description_excerpt
  json.match result.match
  json.matched_variant result.matched_variant if result.match == "variant"
  json.usage_count(@usage_counts&.fetch(result.term.name, 0)) if @usage_counts
end
