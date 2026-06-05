class Curate::RecentChangesController < CurateController

  def index
    @versions = PaperTrail::Version

    @versions = @versions.reorder(created_at: :desc)

    respond_to do |format|
      format.html {
        @pagy, @versions = pagy(:offset, @versions)
      }
      format.json
    end
  end

end
