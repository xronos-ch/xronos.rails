class ControlledVocabulariesController < ApplicationController
  authorize_resource class: "ControlledVocabulary"

  MAX_RESULTS = 20

  # GET /controlled_vocabularies.json?vocabulary=part_of_organism&q=maize
  def index
    name = params[:vocabulary]
    return head :bad_request if name.blank? || name.is_a?(Array)

    @vocabulary = ControlledVocabulary.find_by(name: name)
    return head :not_found unless @vocabulary

    @terms = @vocabulary.terms
    @terms = @terms.search(params[:q]) if params[:q].present?
    @terms = @terms.limit(MAX_RESULTS)

    respond_to do |format|
      format.json
    end
  end
end
