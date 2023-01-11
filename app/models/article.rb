class Article < ApplicationRecord
  enum section: [ :news, :about, :docs ], _suffix: true

  belongs_to :user

  validates :title, presence: true
  validates :section, presence: true
  validates :slug, presence: true, uniqueness: true, format: {
    with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/,
    message: "may only contain lowercase letters, numbers, and hyphens (-)"
  }

  def path
    section + '/' + slug
  end

  def body_html
    Kramdown::Document.new(body).to_html
  end
end
