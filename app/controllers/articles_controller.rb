class ArticlesController < ApplicationController

  load_and_authorize_resource

  # GET /:section
  # GET /:section.atom
  # GET /:section.rss
  def index
    @articles = Article
      .published
      .where(section: params[:section])
      .order(published_at: :desc)

    feed_limit = 20

    respond_to do |format|
      format.html {
        @pagy, @articles = pagy(:offset, @articles, limit: feed_limit)
      }
      format.atom {
        @pagy, @articles = pagy(:offset, @articles, limit: feed_limit)
      }
      format.rss {
        @feed_limit = feed_limit
      }
    end

  end

  # GET /:section/:slug
  def show
    @article = Article.find_by(slug: params[:slug])
    if @article.blank?
      render file: "public/404.html", status: :not_found
    end
  end

end
