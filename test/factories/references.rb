# == Schema Information
#
# Table name: references
#
#  id            :bigint           not null, primary key
#  bibtex        :text
#  short_ref     :string
#  superseded_by :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_references_on_short_ref      (short_ref)
#  index_references_on_superseded_by  (superseded_by)
#
FactoryBot.define do
  
  factory :reference do
    bibtex { Faker::Lorem.paragraph }
    short_ref { Faker::Name.last_name + Faker::Number.between(from: 1900, to: 2020).to_s }
  end
  
end
