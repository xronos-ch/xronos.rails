class PagesController < ApplicationController
  def home
    @news = Article
      .news_section
      .published
      .includes(user: :user_profile, splash_attachment: :blob)
      .order(published_at: :desc)
      .limit(5)
  end
end