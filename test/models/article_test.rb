# == Schema Information
#
# Table name: articles
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  body               :text
#  publish            :boolean          default(FALSE)
#  published_at       :datetime
#  section            :integer          not null
#  slug               :string
#  splash_attribution :string
#  title              :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_id            :bigint
#
# Indexes
#
#  index_articles_on_section  (section)
#  index_articles_on_slug     (slug) UNIQUE
#  index_articles_on_user_id  (user_id)
#
require "test_helper"

class ArticleTest < ActiveSupport::TestCase

  # --- Factory baseline ---

  test "factory builds a valid draft article" do
    article = build(:article)

    assert article.valid?
    assert_not article.publish
    assert_nil article.published_at
  end

  # --- Publication states ---

  test "draft has no publication date" do
    article = build(:article, :draft)

    assert_not article.publish
    assert_nil article.published_at
  end

  test "published article has past published_at" do
    article = build(:article, :published)

    assert article.publish
    assert article.published_at.present?
    assert_operator article.published_at, :<=, Time.zone.now
  end

  test "scheduled article has future published_at" do
    article = build(:article, :scheduled)

    assert article.publish
    assert article.published_at.present?
    assert_operator article.published_at, :>, Time.zone.now
  end

  # --- Draft/published methods ---

  test "published? returns true for published past articles" do
    article = build(:article, :published)

    assert article.published?
    assert_not article.scheduled?
    assert_not article.draft?
  end

  test "scheduled? returns true for future published articles" do
    article = build(:article, :scheduled)

    assert article.scheduled?
    assert_not article.published?
    assert_not article.draft?
  end

  test "draft? returns true when publish is false" do
    article = build(:article, :draft)

    assert article.draft?
    assert_not article.published?
    assert_not article.scheduled?
  end

  test "unpublished article with past date is still draft" do
    article = build(:article, :unpublished_but_dated)

    assert article.draft?
    assert_not article.published?
    assert_not article.scheduled?
  end

  # --- Sections ---

  test "news article has section news" do
    article = build(:article, :news)
    assert_equal "news", article.section
  end

  test "about article has section about" do
    article = build(:article, :about)
    assert_equal "about", article.section
  end

  # --- Ordering ---

  test "articles can be ordered by published_at" do
    older = create(:article, :published, published_at: 2.weeks.ago)
    newer = create(:article, :published, published_at: 1.day.ago)

    assert_operator newer.published_at, :>, older.published_at
  end

  # --- Scopes ---

  test "published scope returns only current published articles" do
    published = create(:article, :published)
    scheduled = create(:article, :scheduled)
    draft     = create(:article, :draft)

    results = Article.published

    assert_includes results, published
    assert_not_includes results, scheduled
    assert_not_includes results, draft
  end

  test "published scope matches published? predicate" do
    articles = [
      create(:article, :published),
      create(:article, :scheduled),
      create(:article, :draft)
    ]

    scope_ids = Article.published.pluck(:id)

    articles.each do |article|
      if article.published?
        assert_includes scope_ids, article.id
      else
        assert_not_includes scope_ids, article.id
      end
    end
  end

  test "published scope includes articles published now" do
    now = Time.zone.now

    article = create(:article, publish: true, published_at: now)

    assert_includes Article.published, article
  end

  test "published scope excludes future articles" do
    article = create(:article, publish: true, published_at: 1.day.from_now)

    assert_not_includes Article.published, article
  end

  test "published scope excludes drafts with past date" do
    article = create(:article, publish: false, published_at: 1.day.ago)

    assert_not_includes Article.published, article
  end

end
