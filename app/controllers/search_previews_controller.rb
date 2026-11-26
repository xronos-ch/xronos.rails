# frozen_string_literal: true

# Renders the short result list shown beneath the public search field.
class SearchPreviewsController < ApplicationController
  skip_before_action :store_user_location!

  def index
    query = params.permit(:q)[:q].to_s.strip
    return head :no_content if query.length < 3

    records = Search.results(query).limit(6).includes(:searchable).filter_map(&:searchable)
    render :index, formats: :html, layout: false, locals: { query: query, records: records }
  end
end
