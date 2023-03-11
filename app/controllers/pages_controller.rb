class PagesController < ApplicationController

  def home
    @news = Article.news_section.published.order(published_at: :desc).limit(5)
  end

end
