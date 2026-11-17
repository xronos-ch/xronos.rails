# The list of OBO source files XRONOS uses. Shared by:
#   db/seeds/controlled_vocabulary.rb (the seed script)
#   lib/tasks/vocabularies.rake       (the fetch task)
#
# Add a new source by appending an entry here. The seed script picks
# the matching filter from a constant in the seed file; the fetch
# task reads the URL and writes the file at the path.
SOURCES = [
  { vocabulary: 'part_of_organism', source_key: 'uberon',
    path:       'db/data/ontologies/uberon-basic.obo',
    url:        'https://purl.obolibrary.org/obo/uberon/uberon-basic.obo' },
  { vocabulary: 'part_of_organism', source_key: 'po',
    path:       'db/data/ontologies/po.obo',
    url:        'https://purl.obolibrary.org/obo/po.obo' }
].freeze
