class DuplicatesController < ApplicationController

  def index
    @sites = Site.all_duplicated
    @pagy, @sites = pagy(:offset, @sites)
  end

end
