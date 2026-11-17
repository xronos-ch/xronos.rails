json.array! @functional_classifications do |classification|
  json.id classification.id
  json.assignable_type classification.assignable_type
  json.assignable_id classification.assignable_id

  json.confidence classification.confidence

  json.category classification.functional_classification_category&.name
  json.confidence_rank FunctionalClassification.confidences[classification.confidence]
  json.source classification.source
  json.note classification.note

  json.created_at classification.created_at
  json.updated_at classification.updated_at
end