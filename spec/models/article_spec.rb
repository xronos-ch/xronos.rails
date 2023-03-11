# == Schema Information
#
# Table name: articles
#
#  id                 :bigint           not null, primary key
#  body               :text
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
require 'rails_helper'

RSpec.describe Article, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
