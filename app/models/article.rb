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
