class FunctionalClassificationsController < ApplicationController
  load_and_authorize_resource

  def index
    @functional_classifications = FunctionalClassification.includes(
      :functional_classification_category,
      :functional_classification_confidence
    )

    if params[:assignable_type].present?
      @functional_classifications = @functional_classifications.where(
        assignable_type: params[:assignable_type]
      )
    end

    if params[:assignable_id].present?
      @functional_classifications = @functional_classifications.where(
        assignable_id: params[:assignable_id]
      )
    end

    respond_to do |format|
      format.json
    end
  end

  def create
    @functional_classification = FunctionalClassification.new(functional_classification_params)

    if @functional_classification.save
      redirect_to return_location,
                  notice: "Functional classification was created."
    else
      redirect_to return_location,
                  alert: @functional_classification.errors.full_messages.to_sentence
    end
  end

  def update
    @functional_classification = FunctionalClassification.find(params[:id])

    if @functional_classification.update(functional_classification_params)
      redirect_to return_location,
                  notice: "Functional classification was updated."
    else
      redirect_to return_location,
                  alert: @functional_classification.errors.full_messages.to_sentence
    end
  end

  def destroy
    @functional_classification = FunctionalClassification.find(params[:id])
    @functional_classification.destroy

    redirect_to return_location,
                notice: "Functional classification was removed."
  end

  private

  def functional_classification_params
    params.require(:functional_classification).permit(
      :assignable_type,
      :assignable_id,
      :functional_classification_category_id,
      :functional_classification_confidence_id,
      :source,
      :note
    )
  end

  def return_location
    params[:return_to].presence || issues_contexts_path
  end
end