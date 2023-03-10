# == Schema Information
#
# Table name: articles
#
#  id           :bigint           not null, primary key
#  body         :text
#  published_at :datetime
#  section      :integer          not null
#  slug         :string
#  title        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint
#
# Indexes
#
#  index_articles_on_section  (section)
#  index_articles_on_slug     (slug) UNIQUE
#  index_articles_on_user_id  (user_id)
#
class Article < ApplicationRecord
  enum section: [ :news, :about, :docs ], _suffix: true

  belongs_to :user
  has_one_attached :splash

  # Workaround lack of named attachment variants in Rails <7
  def splash_variant(variant)
    return nil unless splash.present?
    case variant
    when :card
      splash.variant(resize_to_fill: [1320, 160])
    when :xs
      splash.variant(resize_to_fill: [576, 320])
    when :sm
      splash.variant(resize_to_fill: [768, 320])
    when :md
      splash.variant(resize_to_fill: [992, 320])
    when :lg
      splash.variant(resize_to_fill: [1200, 320])
    when :xl
      splash.variant(resize_to_fill: [1400, 320])
    when :xxl
      splash.variant(resize_to_fill: [2500, 320])
    end
  end

  validates :title, presence: true
  validates :section, presence: true
  validates :slug, presence: true, uniqueness: true, format: {
    with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/,
    message: "may only contain lowercase letters, numbers, and hyphens (-)"
  }

  scope :published, -> { 
    where("published_at <= ?", DateTime.now)
  }

  def published?
    published_at.present? and published_at <= DateTime.now
  end

  def scheduled?
    published_at.present? and published_at > DateTime.now
  end

  def draft?
    !(published? or scheduled?)
  end

  def path
    section + '/' + slug
  end

  def body_html
    Kramdown::Document.new(body).to_html
  end
end
