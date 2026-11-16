# frozen_string_literal: true

module Curate
  # Lists and resolves pairs of possible site duplicates.
  class SiteDuplicatesController < CurateController
    layout 'curate'

    before_action { authorize! :duplicates, Site }

    def index
      pairs = Site::DuplicateReview.review_queue
      @pagy, @pairs = pagy(:offset, pairs)
      ids = @pairs.flat_map { |pair| [pair.first_id, pair.second_id] }.uniq
      @sites = Site.where(id: ids).index_by(&:id)
    end

    def show
      @review = load_review(params[:id], params[:candidate_id])
      @review.evidence
    end

    def create
      fields = merge_params
      review = load_review(fields[:first_id], fields[:second_id])
      target = apply_selection(review, fields)
      redirect_to merge_destination(target), notice: 'Sites merged.', status: :see_other
    rescue Site::CustomDuplicateValues::InvalidValue, Site::DuplicateReview::ContextConfirmationRequired,
           Site::DuplicateContextChoices::InvalidName => e
      @review = review
      @selection = fields.to_h
      @merge_error = e.message
      render :show, status: :unprocessable_entity
    rescue Site::DuplicateReview::LinkedResourceConflict => e
      redirect_to curate_site_duplicate_path(fields[:first_id], candidate_id: fields[:second_id]),
                  alert: e.message, status: :see_other
    rescue Site::DuplicateReview::InvalidSelection, Site::DuplicateReview::StaleReview,
           ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid
      redirect_to curate_site_duplicates_path, alert: 'The sites or selection changed. Review the pair again.',
                                               status: :see_other
    end

    private

    def merge_destination(target)
      return site_path(target, from: 'site_duplicates') unless params[:intent] == 'next'

      pair = Site::DuplicateReview.review_queue.first
      return curate_site_duplicates_path unless pair

      curate_site_duplicate_path(pair.first_id, candidate_id: pair.second_id)
    end

    def merge_params
      params.expect(merge: [
                      :first_id, :second_id, :target_id, :fingerprint, :keep_names, :confirm_contexts,
                      { sources: Site::DuplicateReview::FIELD_GROUPS.keys, custom: %i[name lat lng country_code],
                        separate_contexts: [%i[context_id name]] }
                    ])
    end

    def apply_selection(review, fields)
      review.apply!(target_id: fields[:target_id], fingerprint: fields[:fingerprint],
                    sources: fields[:sources].to_h, keep_names: fields[:keep_names] == '1',
                    confirm_contexts: fields[:confirm_contexts] == '1', custom_values: fields[:custom].to_h,
                    separate_contexts: fields.fetch(:separate_contexts, []).map(&:to_h))
    end

    def load_review(first_id, second_id)
      raise ActiveRecord::RecordNotFound unless [first_id, second_id].all?(&:present?) && first_id != second_id

      Site::DuplicateReview.new(Site.find([first_id, second_id]))
    end
  end
end
