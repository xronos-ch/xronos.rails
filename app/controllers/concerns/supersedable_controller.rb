module SupersedableController

  extend ActiveSupport::Concern

  included do #instance methods
    before_action :redirect_if_superseded, only: :show

    private

    def redirect_if_superseded
      record = controller_name.classify.constantize.unscoped.find(params[:id])
      if record.superseded?
        redirect_to record.ultimately_superseded_by, :status => 301
      end
    end
  end

  class_methods do
  end

end
