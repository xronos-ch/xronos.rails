json.array! @functional_classifications do |classification|
  json.id classification.id
  json.assignable_type classification.assignable_type
  json.assignable_id classification.assignable_id

  json.functional_classification_category_id classification.functional_classification_category_id
  json.functional_classification_confidence_id classification.functional_classification_confidence_id

  json.category classification.functional_classification_category&.name
  json.confidence classification.functional_classification_confidence&.name
  json.source classification.source
  json.note classification.note

  json.created_at classification.created_at
  json.updated_at classification.updated_at
end