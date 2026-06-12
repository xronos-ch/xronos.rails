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
class Article < ApplicationRecord
  enum :section, %i[news about docs], suffix: true

  belongs_to :user
  has_one_attached :splash

  has_one_attached :splash do |attachable|
    attachable.variant :card, resize_to_fill: [1320, 160]
    attachable.variant :xs,   resize_to_fill: [576, 320]
    attachable.variant :sm,   resize_to_fill: [768, 320]
    attachable.variant :md,   resize_to_fill: [992, 320]
    attachable.variant :lg,   resize_to_fill: [1200, 320]
    attachable.variant :xl,   resize_to_fill: [1400, 320]
    attachable.variant :xxl,  resize_to_fill: [2500, 320]
    attachable.variant :og, resize_to_fill: [1200, 630, { gravity: "center" }]
  end

  validates :title, presence: true
  validates :section, presence: true
  validates :slug, presence: true, uniqueness: true, format: {
    with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/,
    message: "may only contain lowercase letters, numbers, and hyphens (-)"
  }

  before_save :set_published_at

  scope :published, -> { 
    where(publish: true)
      .where("published_at <= ?", Time.zone.now)
  }

  def published?
    publish and published_at <= Time.zone.now
  end

  def scheduled?
    publish and published_at > Time.zone.now
  end

  def draft?
    not publish
  end

  def path
    section + '/' + slug
  end

  def document
    Kramdown::Document.new body
  end

  def body_html
    document.to_html
  end

  def toc
    toc = Kramdown::Converter::Toc.convert document.root
    toc.size > 1 ? toc.first : toc
  end

  def author_name
    if about_section? or user.user_profile.blank? or user.user_profile.full_name.blank?
      "XRONOS Core Team"
    else
      user.user_profile.full_name
    end
  end

  def publication_date
    return "nd." unless published?
    if news_section?
      published_at.strftime("%F")
    else
      updated_at.strftime("%F")
    end
  end

  private

  def set_published_at
    if publish and published_at.blank?
      self.published_at = DateTime.now
    end
  end
end
