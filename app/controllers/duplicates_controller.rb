class DuplicatesController < ApplicationController
  include Pagy::Backend

  def index
    @site_dupes = Site.all_exact_duplicates
    @pagy, @site_dupes = pagy_array(@site_dupes)
  end

end
