class AboutController < ApplicationController

  def show
    if File.exist?(page_path)
      file = File.read(page_path)
      @content = Kramdown::Document.new(file).to_html
      render template: "about/_page"
    else
      render file: "public/404.html", status: :not_found
    end
  end

  private

  def page_path
    Pathname.new(Rails.root + "app/views/about/#{params[:page]}.md")
  end

end
