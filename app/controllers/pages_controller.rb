class PagesController < ApplicationController

  def home
    @news = Article
      .news_section
      .published
      .order(published_at: :desc)
      .limit(5)
      .includes([splash_attachment: :blob])
      .includes(:user)
  end

end
