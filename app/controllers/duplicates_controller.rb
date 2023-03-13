class DuplicatesController < ApplicationController
  include Pagy::Backend

  def index
    @sites = Site.all_duplicated
    @pagy, @sites = pagy(@sites)
  end

end
