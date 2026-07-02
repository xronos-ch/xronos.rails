module SupersedableController
  extend ActiveSupport::Concern

  included do
    before_action :redirect_if_superseded, only: :show
  end

  private

  def redirect_if_superseded
    record = controller_name.classify.constantize.unscoped.find(params[:id])
    return unless record.superseded?

    canonical = record.ultimately_superseded_by
    return if canonical == record

    redirect_to url_for(canonical), status: :moved_permanently
  end
end
