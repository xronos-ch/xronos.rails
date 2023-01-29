class DuplicatesController < ApplicationController
  include Pagy::Backend

  def index
    @site_dupes = Site.exactly_duplicated_grouped
    @pagy, @site_dupes = pagy_array(@site_dupes)
  end

end
