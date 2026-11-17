##
# Helper methods for generating citations to XRONOS pages
module CiteAsHelper

  ##
  # Generate citation for an article
  def article_citation(article)
    <<~TEXT
      #{article.author_name} (#{article.publication_date}), #{article.title}.
      <cite>#{article_citation_publication(article)}</cite>.
      #{link_to(article_url(article.section, article.slug))}.
      Accessed #{Time.current.strftime("%F")}.
    TEXT
  end

  private

  def article_citation_publication(article)
    article.news_section? ? "XRONOS News" : "XRONOS"
  end

end
