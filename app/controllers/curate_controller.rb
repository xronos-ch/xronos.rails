class CurateController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    @n_site = Site.count
    @n_c14 = C14Measurement.count
    @n_dendro = 0
    @n_type = 0
  end
end
