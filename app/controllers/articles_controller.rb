class ArticlesController < ApplicationController
  include Pagy::Backend

  load_and_authorize_resource

  # GET /:section
  def index
    @articles = Article
      .published
      .where(section: params[:section])
      .order(published_at: :desc)
    @pagy, @articles = pagy(@articles)
  end

  # GET /:section/:slug
  def show
    @article = Article.find_by(slug: params[:slug])
    if @article.blank?
      render file: "public/404.html", status: :not_found
    end
  end

end
