class StaticPagesController < ApplicationController
  def acknowledgements
    markdown = Rails.root.join("config/static/acknowledgements.md").read
    @acknowledgements_html = Kramdown::Document.new(markdown).to_html
  end
end
