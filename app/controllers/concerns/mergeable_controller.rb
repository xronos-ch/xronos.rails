# frozen_string_literal: true

module MergeableController
  extend ActiveSupport::Concern

  included do
    before_action :check_pending_merge, only: :update
  end

  private

  def check_pending_merge
    return if params[:confirm_merge]

    record = find_mergeable_record
    return unless record.respond_to?(:find_exact_duplicate)

    record.assign_attributes(merge_check_params)
    @merge_duplicate = record.find_exact_duplicate
    @merge_duplicate ||= record.find_cross_sample_duplicate if record.respond_to?(:find_cross_sample_duplicate)
    return unless @merge_duplicate

    respond_to_merge_conflict
  end

  def respond_to_merge_conflict
    respond_to do |format|
      format.html { render :edit }
      format.turbo_stream do
        render turbo_stream: turbo_stream.update('remoteModal-body', partial: 'form')
      end
      format.json { render json: { error: 'merge_pending', duplicate_id: @merge_duplicate.id }, status: :conflict }
    end
  end

  def find_mergeable_record
    instance_variable_get(:"@#{controller_name.singularize}")
  end

  def merge_check_params
    controller_name.singularize
                   .then { |key| params.fetch(key, {}) }
                   .permit!
  end
end
