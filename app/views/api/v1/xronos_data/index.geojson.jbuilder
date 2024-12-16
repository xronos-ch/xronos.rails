json.array! @sites do |site|
  next if site.lng.blank? | site.lat.blank?
  json.type "Feature"
  json.geometry do
    json.type "Point"
    json.coordinates [site.lng.to_f, site.lat.to_f]
  end
  json.properties do
    json.name site.name
    json.id site.id
  end
end