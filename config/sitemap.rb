# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://xronos.ch"

SitemapGenerator::Sitemap.create do
  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: add(path, options={})
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly',
  #           :lastmod => Time.now, :host => default_host
  #
  # Examples:
  #
  # Add '/articles'
  #
  #   add articles_path, :priority => 0.7, :changefreq => 'daily'
  #
  # Add all articles:
  #
  #   Article.find_each do |article|
  #     add article_path(article), :lastmod => article.updated_at
  #   end
  
  group sitemaps_path: "sitemaps", filename: "pages" do
    add "/data", priority: nil, changefreq: nil
    add "/database", priority: nil, changefreq: nil
    add "/api", priority: nil, changefreq: nil
    add "/search", priority: nil, changefreq: nil
  end

  group sitemaps_path: "sitemaps", filename: "articles" do
    Article.published.find_each do |article|
      add article.path, lastmod: article.updated_at, priority: nil, changefreq: nil
    end
  end

  group sitemaps_path: "sitemaps", filename: "indexes" do
    add c14s_path, priority: nil, changefreq: nil
    add references_path, priority: nil, changefreq: nil
    add sites_path, priority: nil, changefreq: nil
    add typos_path, priority: nil, changefreq: nil
  end

  group sitemaps_path: "sitemaps", filename: "c14s" do
    C14.find_each do |c14|
      add c14_path(c14), lastmod: c14.updated_at, priority: nil, changefreq: nil
    end
  end

  group sitemaps_path: "sitemaps", filename: "references" do
    Reference.find_each do |reference|
      add reference_path(reference), lastmod: reference.updated_at, priority: nil, changefreq: nil
    end
  end

  group sitemaps_path: "sitemaps", filename: "sites" do
    Site.find_each do |site|
      add sites_path(site), lastmod: site.updated_at, priority: nil, changefreq: nil
    end
  end

  group sitemaps_path: "sitemaps", filename: "typos" do
    Typo.find_each do |typo|
      add typo_path(typo), lastmod: typo.updated_at, priority: nil, changefreq: nil
    end
  end
end
