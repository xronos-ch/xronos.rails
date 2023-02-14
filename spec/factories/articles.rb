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
FactoryBot.define do
  factory :article do
    section { "" }
    slug { "" }
    title { "" }
    user { "" }
    published_at { "2023-01-10 14:30:31" }
    body { "MyText" }
  end
end
