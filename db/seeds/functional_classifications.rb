functional_categories = [
  ["settlement", "Contexts associated with settlement activity or domestic occupation."],
  ["burial", "Contexts associated with burial, funerary activity, or human remains."],
  ["ritual_ceremonial", "Contexts interpreted as ritual or ceremonial."],
  ["production", "Contexts associated with production, craft, or specialised activity areas."],
  ["hoard", "Contexts associated with hoards or structured deposits."],
  ["palaeoenvironmental", "Samples from palaeoenvironmental or off-site environmental contexts."],
  ["natural", "Natural contexts without clear anthropogenic association."],
  ["mixed", "Contexts with mixed or multiple functional associations."],
  ["unknown", "Contexts for which no functional classification can currently be assigned."]
]

functional_categories.each do |name, description|
  FunctionalClassificationCategory.find_or_initialize_by(name: name).tap do |category|
    category.description = description
    category.save!
  end
end

functional_confidences = [
  ["secure", 3, "The classification is directly supported by explicit contextual information."],
  ["probable", 2, "The classification is likely, but based on indirect or incomplete information."],
  ["possible", 1, "The classification is plausible, but uncertain."],
  ["unknown", 0, "The confidence of the classification is unknown or has not been assessed."]
]

functional_confidences.each do |name, rank, description|
  FunctionalClassificationConfidence.find_or_initialize_by(name: name).tap do |confidence|
    confidence.rank = rank
    confidence.description = description
    confidence.save!
  end
end