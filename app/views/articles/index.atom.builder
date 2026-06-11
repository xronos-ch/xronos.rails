atom_feed do |feed|
  feed.title("XRONOS – News")
  feed.updated @articles.first&.published_at || Time.current

  # Pagination (atom only)
  feed.link href: url_for(page: nil, format: :atom), rel: "alternate"
  feed.link href: url_for(page: @pagy.page, format: :atom), rel: "self"
  feed.link href: url_for(page: @pagy.next, format: :atom), rel: "next" if @pagy.next
  feed.link href: url_for(page: @pagy.previous, format: :atom), rel: "prev" if @pagy.previous

  @articles.first(@pagy.limit).each do |article|
    article_url = article_url section: article.section, slug: article.slug
    feed.entry article, url: article_url do |entry|
      entry.title article.title
      entry.content article.body_html, type: "html"

      entry.author do |author|
        user_profile = article.user.user_profile
        if user_profile.present? 
          author.name user_profile.full_name
          author.uri user_profiles_url(user_profile)
        else
          author.name("XRONOS")
          author.uri(root_url)
        end
      end

      entry.updated article.updated_at
      entry.published article.published_at

      entry.url article_url
      entry.id article_url
    end
  end
end

