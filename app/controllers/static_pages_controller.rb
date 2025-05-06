class StaticPagesController < ApplicationController
  def acknowledgements
    @content = YAML.load_file(Rails.root.join('config/static/acknowledgements.yml'))
  end
end
