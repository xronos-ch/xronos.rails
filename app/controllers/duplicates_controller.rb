class DuplicatesController < ApplicationController
  include Pagy::Backend

  def index
    @sites = Site.all_exact_duplicates
    @pagy, @sites = pagy(@sites)
  end

end
