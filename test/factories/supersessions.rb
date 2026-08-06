# == Schema Information
#
# Table name: supersessions
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  superseded_by_type :string           not null
#  superseded_type    :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  superseded_by_id   :bigint           not null
#  superseded_id      :bigint           not null
#
# Indexes
#
#  index_supersessions_on_superseded_by   (superseded_by_type,superseded_by_id)
#  index_supersessions_unique_superseded  (superseded_type,superseded_id) UNIQUE
#
FactoryBot.define do
  factory :supersession do
    superseded    { create(:site) }
    superseded_by { create(:site) }
  end
end
