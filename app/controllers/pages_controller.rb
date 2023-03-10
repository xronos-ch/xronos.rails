class PagesController < ApplicationController

  def home
    @news = Article.news_section.order(published_at: :desc).limit(5)
  end

end
