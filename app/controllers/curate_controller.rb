class CurateController < ApplicationController
  before_action :authenticate_user!

  def index
    @n_site = Site.count
    @n_c14 = C14.count
    @n_dendro = Dendro.count
    @n_typo = Typo.count
  end

  def import
    render "import", layout: "curate"
  end
end
