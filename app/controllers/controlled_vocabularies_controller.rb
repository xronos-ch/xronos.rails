class ControlledVocabulariesController < ApplicationController
  authorize_resource class: "ControlledVocabulary"

  MAX_RESULTS = 20

  Result = Struct.new(:term, :match, :matched_variant, keyword_init: true) do
    delegate :name, :ontology_name, :ontology_id, :ontology_url, :description_excerpt,
      to: :term
  end

  # GET /controlled_vocabularies.json?vocabulary=part_of_organism&q=maize
  def index
    return head :bad_request if params[:vocabulary].blank? || params[:vocabulary].is_a?(Array)

    @vocabulary = ControlledVocabulary.find_by(name: params[:vocabulary])
    return head :not_found unless @vocabulary

    @results = build_index_results

    respond_to(&:json)
  end

  private

  def build_index_results
    return default_results if params[:q].blank?

    results = []
    excluded_ids = []

    @vocabulary.search_variants(params[:q]).each do |variant|
      results << Result.new(term: variant.term, match: "variant",
                            matched_variant: variant.value)
      excluded_ids << variant.controlled_vocabulary_term_id
    end

    remaining = MAX_RESULTS - results.length
    if remaining.positive?
      term_scope = @vocabulary.terms
                              .search(params[:q])
                              .where.not(id: excluded_ids)
                              .limit(remaining)
      term_scope.each { |t| results << Result.new(term: t, match: "term") }
    end

    results.first(MAX_RESULTS)
  end

  def default_results
    @vocabulary.terms.limit(MAX_RESULTS).map do |t|
      Result.new(term: t, match: "term")
    end
  end
end
