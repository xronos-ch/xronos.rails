##
# Helper methods for generating citations to XRONOS pages
module CiteAsHelper

  ##
  # Generate citation for an article
  def article_citation(article)
    safe_join([
      "#{article.author_name} (#{article.publication_date}), #{article.title}. ",
      tag.cite(article_citation_publication(article)),
      ". ",
      link_to(article_url(article.section, article.slug)),
      ". Accessed #{Time.current.strftime('%F')}."
    ])
  end

  private

  def article_citation_publication(article)
    article.news_section? ? "XRONOS News" : "XRONOS"
  end

end
