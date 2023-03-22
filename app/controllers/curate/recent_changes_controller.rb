class Curate::RecentChangesController < CurateController
  include Pagy::Backend

  def index
    @versions = PaperTrail::Version

    @versions = @versions.reorder(created_at: :desc)

    respond_to do |format|
      format.html { 
        @pagy, @versions = pagy(@versions)
      }
      format.json
    end
  end

end
