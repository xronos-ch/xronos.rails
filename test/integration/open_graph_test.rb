require "test_helper"

class OpenGraphTest < ActionDispatch::IntegrationTest

  #
  # Helper methods
  #
  def doc
    @doc ||= Nokogiri::HTML(@response.body)
  end

  def meta_tag(property)
    doc.at(%(meta[property="#{property}"]))
  end

  def assert_meta(property, expected = nil)
    tag = meta_tag(property)

    assert tag, "Expected meta tag #{property} to be present"

    if expected
      assert_equal expected, tag["content"],
                   "Expected #{property} to be #{expected}, got #{tag['content']}"
    end
  end

  def refute_meta(property)
    assert_nil meta_tag(property),
               "Expected meta tag #{property} to be absent"
  end

  #
  # Site-wide defaults
  #
  test "includes default OpenGraph metadata" do
    get root_path
    assert_response :success

    assert_meta "og:type", "website"
    assert_meta "og:site_name", "XRONOS"

    assert meta_tag("og:title")
    assert meta_tag("og:description")
    assert meta_tag("og:image")
  end

  #
  # Article overrides
  #
  test "article sets OpenGraph metadata" do
    article = create(:article,
      title: "Test Article",
      body: "<p>Hello world</p>",
      published_at: Time.current
    )

    get article_path(article.section, article.slug)
    assert_response :success

    assert_meta "og:type", "article"
    assert_meta "og:title", "Test Article"
    assert_meta "og:url", article_url(article.section, article.slug)
  end

  #
  # Description behaviour
  #
  test "article sets OpenGraph description" do
    article = create(:article,
      body: "<p>#{'Long text ' * 50}</p>"
    )

    get article_path(article.section, article.slug)

    tag = meta_tag("og:description")
    assert tag
    refute_empty tag["content"]
  end

  #
  # Image selection
  #
  test "article uses splash image for og:image" do
    article = create(:article)

    article.splash.attach(
      io: StringIO.new("fake"),
      filename: "test.jpg",
      content_type: "image/jpeg"
    )

    get article_path(article.section, article.slug)

    tag = meta_tag("og:image")
    assert tag
    assert_includes tag["content"], "active_storage"
  end

  test "article falls back to default og image" do
    article = create(:article)

    get article_path(article.section, article.slug)

    assert_includes meta_tag("og:image")["content"], "/og/default"
  end

  #
  # Article metadata
  #
  test "article includes article meta fields" do
    article = create(:article, published_at: Time.current)

    get article_path(article.section, article.slug)

    assert meta_tag("article:published_time")
    assert meta_tag("article:modified_time")
  end
end

