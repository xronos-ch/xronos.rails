# frozen_string_literal: true

# Public multisearch results and the record types they can include.
class Search
  TYPES = %w[Site C14 Reference].freeze

  def self.results(query)
    PgSearch.multisearch(query).merge(visible_documents)
  end

  def self.visible_documents
    documents = PgSearch::Document.all
    TYPES.map do |type|
      documents.where(searchable_type: type, searchable_id: type.constantize.select(:id))
    end.reduce(:or)
  end
  private_class_method :visible_documents
end
