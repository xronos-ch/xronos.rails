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