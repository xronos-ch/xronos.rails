require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  # --- Atom and RSS feeds ---

  test "atom feed returns success and correct content type" do
    get news_url(format: :atom)

    assert_response :success
    assert_equal "application/atom+xml", response.media_type
  end

  test "rss feed returns success and correct content type" do
    get news_url(format: :rss)

    assert_response :success
    assert_equal "application/rss+xml", response.media_type
  end

  test "feed includes only published articles" do
    published = create(:article, :published, title: "Published")
    create(:article, :scheduled, title: "Scheduled")
    create(:article, :draft, title: "Draft")

    get news_url(format: :atom)

    body = response.body

    assert_includes body, "Published"
    assert_not_includes body, "Scheduled"
    assert_not_includes body, "Draft"
  end

  test "feed orders articles by published_at descending" do
    older = create(:article, :published, title: "Older", published_at: 2.days.ago)
    newer = create(:article, :published, title: "Newer", published_at: 1.hour.ago)

    get news_url(format: :atom)

    titles = response.body.scan(/<title>(.*?)<\/title>/).flatten

    assert titles.index("Newer") < titles.index("Older")
  end

  test "feed includes correct article URLs" do
    article = create(:article, :published, section: "news", slug: "test-article")

    get news_url(format: :atom)

    expected_url = article_url(section: "news", slug: "test-article")

    assert_includes response.body, expected_url
  end

  test "atom feed includes required elements" do
    create(:article, :published)

    get news_url(format: :atom)

    body = response.body

    assert_includes body, "<feed"
    assert_includes body, "<entry>"
    assert_includes body, "<id>"
    assert_includes body, "<updated>"
  end

  test "rss feed includes required elements" do
    create(:article, :published)

    get news_url(format: :rss)

    body = response.body

    assert_includes body, "<rss"
    assert_includes body, "<channel>"
    assert_includes body, "<item>"
    assert_includes body, "<guid>"
  end

  test "feed includes author name from user profile" do
    user = create(:user)
    user.user_profile.update!(full_name: "Jane Doe")

    create(:article, :published, user: user)

    get news_url(format: :atom)

    assert_includes response.body, "Jane Doe"
  end

  test "atom feed includes pagination links" do
    create_list(:article, 25, :published)

    get news_url(format: :atom)

    assert_includes response.body, 'rel="self"'
    assert_includes response.body, 'rel="next"'
  end

end
