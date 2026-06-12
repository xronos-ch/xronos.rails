xml.instruct! :xml, version: "1.0", encoding: "UTF-8"

xml.rss version: "2.0", "xmlns:atom" => "http://www.w3.org/2005/Atom" do
  xml.channel do
    xml.title "XRONOS – News"
    xml.link root_url
    xml.description "Latest news from XRONOS, an open data infrastructure for archaeological chronology"
    xml.lastBuildDate (@articles.first&.published_at || Time.current).rfc2822

    # Canonical URL
    xml.tag! "atom:link", rel: "self", type: "application/rss+xml",
      href: news_url(format: :rss)

    @articles.first(@feed_limit).each do |article|
      article_url = article_url(section: article.section, slug: article.slug)

      xml.item do
        xml.title article.title
        xml.link article_url
        xml.guid article_url

        xml.pubDate(article.published_at&.rfc2822 || article.updated_at.rfc2822)

        xml.description do
          xml.cdata! article.body_html
        end

        user_profile = article.user.user_profile

        if user_profile.present?
          xml.author "#{user_profile.public_email} (#{user_profile.full_name})"
        else
          xml.author "admin@xronos.ch (XRONOS)"
        end
      end
    end
  end
end
